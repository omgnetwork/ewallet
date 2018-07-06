defmodule EWalletDB.AccountUserTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.AccountUser

  describe "AccountUser factory" do
    test_has_valid_factory(AccountUser)
  end

  describe "AccountUser.insert/1" do
    test_insert_generate_uuid(AccountUser, :uuid)
    test_insert_generate_timestamps(AccountUser)
    test_insert_prevent_blank(AccountUser, :account_uuid)
    test_insert_prevent_blank(AccountUser, :user_uuid)

    test "prevents inserting an account user without an account" do
      {res, changeset} =
        :account_user
        |> params_for(account_uuid: nil)
        |> AccountUser.insert()

      assert res == :error

      assert Enum.member?(
               changeset.errors,
               {:account_uuid, {"can't be blank", [validation: :required]}}
             )
    end

    test "prevents inserting an account without a user" do
      {res, changeset} =
        :account_user
        |> params_for(user_uuid: nil)
        |> AccountUser.insert()

      assert res == :error

      assert Enum.member?(
               changeset.errors,
               {:user_uuid, {"can't be blank", [validation: :required]}}
             )
    end

    test "prevents multiple account/user to be inserted" do
      account = insert(:account)
      user = insert(:user)
      params = params_for(:account_user, user_uuid: user.uuid, account_uuid: account.uuid)

      {:ok, _changeset} = AccountUser.insert(params)
      {:ok, _changeset} = AccountUser.insert(params)

      assert AccountUser |> Repo.all() |> length() == 1
    end
  end

  describe "link/2" do
    test "links an account and a user" do
      account = insert(:account)
      user = insert(:user)
      {res, account_user} = AccountUser.link(account.uuid, user.uuid)

      assert res == :ok
      assert account_user.account_uuid == account.uuid
      assert account_user.user_uuid == user.uuid
    end

    test "prevents an account and a user from being linked more than once" do
      account = insert(:account)
      user = insert(:user)
      {:ok, _account_user} = AccountUser.link(account.uuid, user.uuid)
      {res, _changeset} = AccountUser.link(account.uuid, user.uuid)

      assert res == :ok
      assert AccountUser |> Repo.all() |> length() == 1
    end

    test "allows a user to be linked with multiple accounts" do
      account_1 = insert(:account)
      account_2 = insert(:account)
      user = insert(:user)
      {res_1, _account_user} = AccountUser.link(account_1.uuid, user.uuid)
      {res_2, _account_user} = AccountUser.link(account_2.uuid, user.uuid)

      assert res_1 == :ok
      assert res_2 == :ok

      assert AccountUser |> Repo.all() |> length() == 2
    end

    test "allows an account to be linked with multiple users" do
      account = insert(:account)
      user_1 = insert(:user)
      user_2 = insert(:user)

      {res_1, _account_user} = AccountUser.link(account.uuid, user_1.uuid)
      {res_2, _account_user} = AccountUser.link(account.uuid, user_2.uuid)

      assert res_1 == :ok
      assert res_2 == :ok

      assert AccountUser |> Repo.all() |> length() == 2
    end
  end
end
