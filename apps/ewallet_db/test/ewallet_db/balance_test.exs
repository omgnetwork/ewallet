defmodule EWalletDB.BalanceTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.{Balance, Account, User}

  describe "Balance factory" do
    test_has_valid_factory Balance
    test_encrypted_map_field Balance, "balance", :encrypted_metadata
  end

  describe "Balance.insert/1" do
    test_insert_ok Balance, :address, "an_address"

    test_insert_generate_uuid Balance, :uuid
    test_insert_generate_uuid Balance, :address
    test_insert_generate_timestamps Balance

    test_insert_prevent_blank Balance, :address
    test_insert_prevent_all_blank Balance, [:account, :user]
    test_insert_prevent_duplicate Balance, :address
    test_default_metadata_fields Balance, "balance"

    test "allows insert if provided a user without account_uuid" do
      {res, _balance} =
        :balance
        |> params_for(%{user: insert(:user), account_uuid: nil})
        |> Balance.insert

      assert res == :ok
    end

    test "allows insert if provided an account without user" do
      {res, _balance} =
        :balance
        |> params_for(%{account: insert(:account), user: nil})
        |> Balance.insert

      assert res == :ok
    end

    test "allows insert if name == genesis" do
      {res, _balance} =
        :balance
        |> params_for(%{account: nil, user: nil, identifier: Balance.genesis()})
        |> Balance.insert

      assert res == :ok
    end

    test "prevents creation of a balance with both a user and account" do
      params = %{user: insert(:user), account: insert(:account)}
      {result, changeset} = :balance |> params_for(params) |> Balance.insert

      assert result == :error
      assert changeset.errors ==
        [{%{account_uuid: nil, identifier: "genesis", user_uuid: nil},
         {"only one must be present", []}}]
    end

    test "prevents creation of a balance without a user and an account" do
      params = %{user: nil, account: nil}
      {result, changeset} = :balance |> params_for(params) |> Balance.insert

      assert result == :error
      assert changeset.errors ==
        [{%{account_uuid: nil, identifier: "genesis", user_uuid: nil},
         {"can't all be blank", []}}]
    end

    test "allows insert of a balance with the same name than one for another account" do
      {:ok, account1} = :account |> params_for() |> Account.insert
      {:ok, account2} = :account |> params_for() |> Account.insert
      balance1 = Account.get_primary_balance(account1)
      balance2 = Account.get_primary_balance(account2)

      assert balance1.name == balance2.name
    end

    test "allows insert of a balance with the same name than one for another user" do
      {:ok, user1} = :user |> params_for() |> User.insert
      {:ok, user2} = :user |> params_for() |> User.insert
      balance1 = User.get_primary_balance(user1)
      balance2 = User.get_primary_balance(user2)

      assert balance1.name == balance2.name
    end

    test "prevents creation of a balance with the same name for the same account" do
      {:ok, account} = :account |> params_for() |> Account.insert
      balance = Account.get_primary_balance(account)
      {res, changeset} = Account.insert_balance(account, balance.name)

      assert res == :error
      assert changeset.errors == [unique_account_name: {"has already been taken", []}]
    end

    test "prevents creation of a balance with the same name for the same user" do
      {:ok, user} = :user |> params_for() |> User.insert
      balance = User.get_primary_balance(user)
      {res, changeset} = User.insert_balance(user, balance.name)

      assert res == :error
      assert changeset.errors == [unique_user_name: {"has already been taken", []}]
    end
  end

  describe "get/1" do
    test "returns an existing balance using an address" do
      :balance
      |> params_for(%{address: "balance_address1234"})
      |> Balance.insert

      balance = Balance.get("balance_address1234")
      assert balance.address == "balance_address1234"
    end

    test "returns nil if the balance address does not exist" do
      assert Balance.get("nonexisting_address") == nil
    end
  end

  describe "get_genesis/0" do
    test "inserts the genesis address if not existing" do
      assert Balance.get("genesis") == nil
      genesis = Balance.get_genesis()
      assert Balance.get("genesis") == genesis
    end

    test "returns the existing genesis address if present" do
      inserted_genesis = Balance.get_genesis()
      genesis = Balance.get_genesis()
      assert inserted_genesis == genesis
    end
  end
end
