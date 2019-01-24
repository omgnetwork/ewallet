# Copyright 2018 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EWalletDB.UserTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias Utils.Helpers.Crypto
  alias EWalletDB.{Account, Invite, User, Repo}
  alias ActivityLogger.{System, ActivityLog}

  describe "User factory" do
    test_has_valid_factory(User)
    test_encrypted_map_field(User, "user", :encrypted_metadata)
  end

  describe "insert/1" do
    test "inserts a user if it does not exist" do
      {:ok, inserted_user} = :user |> params_for |> User.insert()
      user = User.get(inserted_user.id)

      assert user.id == inserted_user.id
      assert user.username == inserted_user.username
      assert user.full_name == inserted_user.full_name
      assert user.calling_name == inserted_user.calling_name
      assert user.provider_user_id == inserted_user.provider_user_id
      assert user.metadata["first_name"] == inserted_user.metadata["first_name"]
      assert user.metadata["last_name"] == inserted_user.metadata["last_name"]

      audits = ActivityLog.all_for_target(User, user.uuid)
      assert length(audits) == 1

      audit = Enum.at(audits, 0)
      assert audit.originator_uuid != nil
      assert audit.originator_type == "system"
    end

    test_insert_generate_uuid(User, :uuid)
    test_insert_generate_external_id(User, :id, "usr_")
    test_insert_generate_timestamps(User)
    test_insert_prevent_duplicate(User, :username)
    test_insert_prevent_duplicate(User, :provider_user_id)
    test_default_metadata_fields(User, "user")

    test "creates a primary wallet for end users" do
      {:ok, inserted_user} = :user |> params_for() |> User.insert()

      assert User.get_primary_wallet(inserted_user) != nil
    end

    test "does not create a wallet for admins" do
      {:ok, inserted_user} = :admin |> params_for() |> User.insert()

      assert User.get_primary_wallet(inserted_user) == nil
    end

    # The test below can't use `test_insert_prevent_duplicate/3` with :email
    # because we need to use :admin factory to get proper data for admin user.
    test "returns error if same :email is already used" do
      params = params_for(:admin, %{email: "same@example.com"})

      {:ok, _record} = User.insert(params)
      {result, changeset} = User.insert(params)

      assert result == :error
      assert changeset.errors == [{:email, {"has already been taken", []}}]
    end

    test "automatically creates a wallet when user is created" do
      {_result, user} = :user |> params_for |> User.insert()
      User.get_primary_wallet(user)
      assert length(User.get(user.id).wallets) == 1
    end
  end

  describe "update/2" do
    test_update_field_ok(User, :username)
    test_update_field_ok(User, :full_name)
    test_update_field_ok(User, :calling_name)

    test_update_field_ok(User, :metadata, %{"field" => "old"}, %{"field" => "new"})

    test_update_field_ok(User, :encrypted_metadata, %{"field" => "old"}, %{
      "field" => "new"
    })

    test_update_prevents_changing(User, :provider_user_id)

    test "does not update the user's email" do
      user = insert(:standalone_user)
      new_email = "new.email@example.com"

      assert user.email != new_email

      {res, updated} =
        User.update(user, %{
          email: new_email,
          originator: user
        })

      assert res == :ok
      assert updated.email == user.email
      assert updated.email != new_email
    end

    test "does not update the user's password" do
      user = insert(:standalone_user)

      {res, updated} =
        User.update(user, %{
          old_password: user.password,
          password: "new_password",
          password_confirmation: "new_password",
          originator: user
        })

      assert res == :ok
      assert updated.password_hash == user.password_hash
    end
  end

  describe "update_password/2" do
    test "updates the password" do
      user = insert(:standalone_user)
      refute Crypto.verify_password("new_password", user.password_hash)

      {res, updated} =
        User.update_password(user, %{
          old_password: user.password,
          password: "new_password",
          password_confirmation: "new_password",
          originator: user
        })

      assert res == :ok
      assert Crypto.verify_password("new_password", updated.password_hash)
    end

    test "allows initial password setting without old_password" do
      user = insert(:user)
      assert user.password_hash == nil

      {res, updated} =
        User.update_password(user, %{
          # old_password: user.password,
          password: "new_password",
          password_confirmation: "new_password",
          originator: user
        })

      assert res == :ok
      assert Crypto.verify_password("new_password", updated.password_hash)
    end

    test "prevents the password update without giving the current password" do
      user = insert(:standalone_user)

      {res, code} =
        User.update_password(user, %{
          # old_password: user.password,
          password: "new_password",
          password_confirmation: "new_password",
          originator: user
        })

      assert res == :error
      assert code == :invalid_old_password
    end

    test "prevents removing the password" do
      user = insert(:standalone_user)

      {res, changeset} =
        User.update_password(user, %{
          old_password: user.password,
          password: nil,
          password_confirmation: nil,
          originator: user
        })

      assert res == :error
      refute changeset.valid?
    end

    test "prevents updating the password that doesn't match the confirmation" do
      user = insert(:standalone_user)

      {res, changeset} =
        User.update_password(user, %{
          old_password: user.password,
          password: "new_password",
          password_confirmation: "a_different_password",
          originator: user
        })

      assert res == :error
      refute changeset.valid?
    end

    test "prevents updating the password that does not pass requirements" do
      user = insert(:standalone_user)

      {res, changeset} =
        User.update_password(user, %{
          old_password: user.password,
          password: "short",
          password_confirmation: "short",
          originator: user
        })

      assert res == :error
      refute changeset.valid?
    end
  end

  describe "update_email/2" do
    test "updates the email" do
      user = insert(:standalone_user)
      new_email = "new.email@example.com"
      assert user.email != new_email

      {res, updated} =
        User.update_email(user, %{
          email: new_email,
          originator: user
        })

      assert res == :ok
      assert updated.email == new_email
    end

    test "prevents the update if the email is already used" do
      new_email = "new.email@example.com"
      user = insert(:standalone_user)
      _ = insert(:standalone_user, email: "new.email@example.com")

      assert user.email != new_email

      {res, changeset} =
        User.update_email(user, %{
          email: new_email,
          originator: user
        })

      assert res == :error
      refute changeset.valid?
      assert changeset.errors == [email: {"has already been taken", []}]
    end

    test "prevents removal of the email" do
      user = insert(:standalone_user)

      assert String.length(user.email) > 0

      {res, changeset} =
        User.update_email(user, %{
          email: nil,
          originator: user
        })

      assert res == :error

      refute changeset.valid?

      assert changeset.errors == [
               email:
                 {"must be a valid email address format",
                  [validation: :valid_email_address_format]},
               email: {"can't be blank", [validation: :required]}
             ]
    end
  end

  describe "get/1" do
    test "returns the existing user" do
      {_, inserted_user} =
        :user
        |> build(%{id: "usr_01caj9wth0vyestkmh7873qb9f"})
        |> Repo.insert()

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
        |> Repo.insert()

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
        |> Repo.insert()

      user = User.get_by_email("test@example.com")
      assert user.email == inserted_user.email
    end

    test "returns nil if user with the given email does not exist" do
      user = User.get_by_email("an_invalid_email")
      assert user == nil
    end
  end

  describe "get_primary_wallet/1" do
    test "returns the first wallet" do
      {:ok, inserted} = User.insert(params_for(:user))
      wallet = User.get_primary_wallet(inserted)

      user =
        inserted.id
        |> User.get()
        |> Repo.preload([:wallets])

      assert wallet != nil
      assert wallet == Enum.at(user.wallets, 0)
    end

    test "make sure only 1 wallet is created at most" do
      {:ok, inserted} = User.insert(params_for(:user))
      wallet_1 = User.get_primary_wallet(inserted)
      wallet_2 = User.get_primary_wallet(inserted)
      assert wallet_1 == wallet_2
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
      user = insert(:user)
      account1 = insert(:account)
      account2 = insert(:account)
      account3 = insert(:account)
      role1 = insert(:role, %{name: "role_one"})
      role2 = insert(:role, %{name: "role_two"})

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
      user = insert(:user)
      account = insert(:account)
      role = insert(:role, %{name: "role_one"})

      insert(:membership, %{user: user, account: account, role: role})

      assert User.get_role(user, account) == "role_one"
    end
  end

  describe "set_admin/2" do
    test "sets the user to admin status when given true" do
      user = insert(:user)
      refute User.admin?(user)

      {:ok, user} = User.set_admin(user, true, %System{})
      assert User.admin?(user)
    end

    test "sets the user to non-admin status when given false" do
      user = insert(:admin)
      assert User.admin?(user)

      {:ok, user} = User.set_admin(user, false, %System{})
      refute User.admin?(user)
    end
  end

  describe "admin?/1" do
    test "returns true if the user's `is_admin` is true" do
      user = insert(:user, is_admin: true)
      assert User.admin?(user)
    end

    test "returns false if the user's `is_admin` is false" do
      user = insert(:user, is_admin: false)
      refute User.admin?(user)
    end
  end

  describe "enabled?/1" do
    test "returns true if the user's `enabled` is true" do
      user = insert(:user, enabled: true)
      assert User.enabled?(user)
    end

    test "returns false if the user's `enabled` is false" do
      user = insert(:user, enabled: false)
      refute User.enabled?(user)
    end
  end

  describe "master_admin?/1" do
    test "returns true if the user has a membership on the top-level account" do
      user = insert(:user)
      master_account = Account.get_master_account()
      role = insert(:role, %{name: "admin"})
      _membership = insert(:membership, %{user: user, account: master_account, role: role})

      assert User.master_admin?(user)
    end

    test "returns false if the user has a membership on the non-top-level account" do
      user = insert(:user)
      account = insert(:account)
      _membership = insert(:membership, %{user: user, account: account})

      refute User.master_admin?(user)
    end

    test "returns false if the user does not have a membership" do
      user = insert(:user)
      refute User.master_admin?(user)
    end
  end

  describe "get_accounts/1" do
    test "returns a list of user's accounts" do
      user = insert(:user)
      account_1 = insert(:account)
      account_2 = insert(:account)
      _account_3 = insert(:account)
      role = insert(:role, %{name: "role_name"})

      insert(:membership, %{user: user, account: account_1, role: role})
      insert(:membership, %{user: user, account: account_2, role: role})

      accounts = user |> User.get_accounts() |> Enum.map(fn account -> account.uuid end)
      assert length(accounts) == 2
      assert Enum.member?(accounts, account_1.uuid)
      assert Enum.member?(accounts, account_2.uuid)
    end
  end

  describe "enable_or_disable/2" do
    test "enable the user when given true" do
      user = insert(:user, %{enabled: false})
      refute User.enabled?(user)

      {:ok, user} =
        User.enable_or_disable(user, %{
          enabled: true,
          originator: %System{}
        })

      assert User.enabled?(user)
    end

    test "disable the user when given false" do
      user = insert(:user, %{enabled: true})
      assert User.enabled?(user)

      {:ok, user} =
        User.enable_or_disable(user, %{
          enabled: false,
          originator: %System{}
        })

      refute User.enabled?(user)
    end
  end
end
