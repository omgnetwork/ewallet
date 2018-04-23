defmodule EWalletDB.UserTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.{Invite, User}

  describe "User factory" do
    test_has_valid_factory User
    test_encrypted_map_field User, "user", :encrypted_metadata
  end

  describe "insert/1" do
    test "inserts a user if it does not exist" do
      {:ok, inserted_user} = :user |> params_for |> User.insert
      user = User.get(inserted_user.id)

      assert user.id == inserted_user.id
      assert user.username == inserted_user.username
      assert user.provider_user_id == inserted_user.provider_user_id
      assert user.metadata["first_name"] == inserted_user.metadata["first_name"]
      assert user.metadata["last_name"] == inserted_user.metadata["last_name"]
    end

    test_insert_generate_uuid User, :uuid
    test_insert_generate_external_id User, :id, "usr_"
    test_insert_generate_timestamps User
    test_insert_prevent_duplicate User, :username
    test_insert_prevent_duplicate User, :provider_user_id
    test_default_metadata_fields User, "user"

    # The test below can't use `test_insert_prevent_duplicate/3` with :email
    # because we need to use :admin factory to get proper data for admin user.
    test "returns error if same :email already exists" do
      params = params_for(:admin, %{email: "same@example.com"})

      {:ok, _record} = User.insert(params)
      {result, changeset} = User.insert(params)

      assert result == :error
      assert changeset.errors == [{:email, {"has already been taken", []}}]
    end

    test "automatically creates a balance when user is created" do
      {_result, user} = :user |> params_for |> User.insert
      User.get_primary_balance(user)
      assert length(User.get(user.id).balances) == 1
    end
  end

  describe "update/2" do
    test_update_field_ok User, :username
    test_update_field_ok User, :metadata, %{"field" => "old"}, %{"field" => "new"}
    test_update_prevents_changing User, :provider_user_id

    test "prevents updating an admin without email" do
      user = prepare_admin_user()
      {res, changeset} = User.update(user, %{email: nil})

      assert res == :error
      refute changeset.valid?
    end

    test "prevents updating an admin without password" do
      user = prepare_admin_user()
      {res, changeset} = User.update(user, %{password: nil})

      assert res == :error
      refute changeset.valid?
    end

    test "prevents updating an admin password that does not pass requirements" do
      user = prepare_admin_user()
      {res, changeset} = User.update(user, %{password: "short"})

      assert res == :error
      refute changeset.valid?
    end
  end

  describe "get/1" do
    test "returns the existing user" do
      {_, inserted_user} =
        :user
        |> build(%{id: "usr_01caj9wth0vyestkmh7873qb9f"})
        |> Repo.insert

      user = User.get("usr_01caj9wth0vyestkmh7873qb9f")
      assert user.uuid == inserted_user.uuid
    end

    test "returns nil if user does not exist" do
      user = User.get("usr_12345678901234567890123456")
      assert user == nil
    end
  end

  describe "get_by_provider_user_id/1" do
    test "returns the existing user from the provider_user_id" do
      {_, inserted_user} =
        :user
        |> build(%{provider_user_id: "1234"})
        |> Repo.insert

      user = User.get_by_provider_user_id("1234")
      assert user.provider_user_id == inserted_user.provider_user_id
    end

    test "returns nil if user does not exist" do
      user = User.get_by_provider_user_id("an_invalid_provider_id")
      assert user == nil
    end
  end

  describe "get_by_email/1" do
    test "returns the existing user from the email" do
      {_, inserted_user} =
        :user
        |> build(%{email: "test@example.com"})
        |> Repo.insert

      user = User.get_by_email("test@example.com")
      assert user.email == inserted_user.email
    end

    test "returns nil if user with the given email does not exist" do
      user = User.get_by_email("an_invalid_email")
      assert user == nil
    end
  end

  describe "get_primary_balance/1" do
    test "returns the first balance" do
      {:ok, inserted} = User.insert(params_for(:user))
      balance = User.get_primary_balance(inserted)

      user =
        inserted.id
        |> User.get()
        |> Repo.preload([:balances])

      assert balance != nil
      assert balance == Enum.at(user.balances, 0)
    end

    test "make sure only 1 balance is created at most" do
      {:ok, inserted} = User.insert(params_for(:user))
      balance_1 = User.get_primary_balance(inserted)
      balance_2 = User.get_primary_balance(inserted)
      assert balance_1 == balance_2
    end
  end

  describe "get_status/1" do
    test "returns :active if the user does not have an associated invite" do
      user = insert(:admin)
      assert User.get_status(user) == :active
    end

    test "returns :pending_confirmation if the user has an associated invite" do
      user = insert(:admin, %{invite: insert(:invite)})
      assert User.get_status(user) == :pending_confirmation
    end
  end

  describe "get_invite/1" do
    test "returns the user's invite if exists" do
      user = insert(:admin, %{invite: insert(:invite)})
      assert %Invite{} = User.get_invite(user)
    end

    test "returns nil if the user's invite does not exist" do
      user = insert(:admin, %{invite: nil})
      assert User.get_invite(user) == nil
    end
  end

  describe "has_membership?/1" do
    test "returns true if the user has a membership with any account" do
      {user, _} = insert_user_with_role("some_role")
      assert User.has_membership?(user)
    end

    test "returns false if the user does not have any membership" do
      user = insert(:user)
      refute User.has_membership?(user)
    end

    test "returns false if the user has not been created yet" do
      user = build(:user)
      refute User.has_membership?(user)
    end
  end

  describe "has_role?/1" do
    test "returns true if the user is assigned to the given role" do
      {user, _} = insert_user_with_role("some_role")
      assert User.has_role?(user, "some_role")
    end

    test "returns false if the user is not assigned to the given role" do
      {user, _} = insert_user_with_role("some_role")
      refute User.has_role?(user, "wrong_role")
    end
  end

  describe "get_roles/1" do
    test "returns a list of unique roles that the given user has" do
      user     = insert(:user)
      account1 = insert(:account)
      account2 = insert(:account)
      account3 = insert(:account)
      role1    = insert(:role, %{name: "role_one"})
      role2    = insert(:role, %{name: "role_two"})

      insert(:membership, %{user: user, account: account1, role: role1})
      insert(:membership, %{user: user, account: account2, role: role2})
      insert(:membership, %{user: user, account: account3, role: role2})
      roles = User.get_roles(user)

      assert Enum.count(roles) == 2
      assert Enum.member?(roles, "role_one")
      assert Enum.member?(roles, "role_two")
    end
  end

  describe "get_role/2" do
    test "returns the role that the user has for the given account's id" do
      user    = insert(:user)
      account = insert(:account)
      role    = insert(:role, %{name: "role_one"})

      insert(:membership, %{user: user, account: account, role: role})

      assert User.get_role(user.id, account.id) == "role_one"
    end

    test "returns the role that the user has in the closest parent account" do
      user    = insert(:user)
      parent  = insert(:account)
      account = insert(:account, parent: parent)
      role    = insert(:role, %{name: "role_from_parent"})

      insert(:membership, %{user: user, account: parent, role: role})

      assert User.get_role(user.id, account.id) == "role_from_parent"
    end

    test "returns nil if the given user is not a member in the account or any of its parents" do
      user    = insert(:user)
      parent  = insert(:account)
      account = insert(:account, parent: parent)

      assert User.get_role(user.id, account.id) == nil
    end
  end

  describe "get_account/1" do
    test "returns an upper-most account that the given user has membership in" do
      user        = insert(:user)
      top_account = insert(:account)
      mid_account = insert(:account, %{parent: top_account})
      _unrelated  = insert(:account)
      role        = insert(:role, %{name: "role_name"})

      insert(:membership, %{user: user, account: mid_account, role: role})
      account = User.get_account(user)

      assert account.id == mid_account.id
    end
  end

  describe "get_accounts/1" do
    test "returns a list of user's accounts and their sub-accounts" do
      user        = insert(:user)
      top_account = insert(:account)
      mid_account = insert(:account, %{parent: top_account})
      sub_account = insert(:account, %{parent: mid_account})
      _unrelated  = insert(:account)
      role        = insert(:role, %{name: "role_name"})

      insert(:membership, %{user: user, account: mid_account, role: role})
      [account1, account2] = User.get_accounts(user)

      assert account1.uuid == mid_account.uuid
      assert account2.uuid == sub_account.uuid
    end
  end
end
