defmodule EWalletDB.UserTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.User

  describe "User factory" do
    test_has_valid_factory User
    test_encrypted_map_field User, "user", :metadata
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

    test_insert_generate_uuid User, :id
    test_insert_generate_timestamps User
    test_insert_prevent_blank User, :metadata
    test_insert_prevent_duplicate User, :username
    test_insert_prevent_duplicate User, :provider_user_id

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
  end

  describe "get/1" do
    test "returns the existing user" do
      {_, inserted_user} =
        :user
        |> build(%{id: "06ba7634-109e-42e6-8f40-52fc5bc08a9c"})
        |> Repo.insert

      user = User.get("06ba7634-109e-42e6-8f40-52fc5bc08a9c")
      assert user.id == inserted_user.id
    end

    test "returns nil if user does not exist" do
      user = User.get("00000000-0000-0000-0000-000000000000")
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
end
