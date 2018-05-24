defmodule EWalletDB.WalletTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.{Wallet, Account, User}

  describe "Wallet factory" do
    test_has_valid_factory(Wallet)
    test_encrypted_map_field(Wallet, "wallet", :encrypted_metadata)
  end

  describe "Wallet.insert/1" do
    test_insert_ok(Wallet, :address, "an_address")

    test_insert_generate_uuid(Wallet, :uuid)
    test_insert_generate_uuid(Wallet, :address)
    test_insert_generate_timestamps(Wallet)

    test_insert_prevent_blank(Wallet, :address)
    test_insert_prevent_all_blank(Wallet, [:account, :user])
    test_insert_prevent_duplicate(Wallet, :address)
    test_default_metadata_fields(Wallet, "wallet")

    test "allows insert if provided a user without account_uuid" do
      {res, _wallet} =
        :wallet
        |> params_for(%{user: insert(:user), account_uuid: nil})
        |> Wallet.insert()

      assert res == :ok
    end

    test "allows insert if provided an account without user" do
      {res, _wallet} =
        :wallet
        |> params_for(%{account: insert(:account), user: nil})
        |> Wallet.insert()

      assert res == :ok
    end

    test "allows insert if name == genesis" do
      {res, _wallet} =
        :wallet
        |> params_for(%{account: nil, user: nil, identifier: Wallet.genesis()})
        |> Wallet.insert()

      assert res == :ok
    end

    test "prevents creation of a wallet with both a user and account" do
      params = %{user: insert(:user), account: insert(:account)}
      {result, changeset} = :wallet |> params_for(params) |> Wallet.insert()

      assert result == :error

      assert changeset.errors ==
               [
                 {%{account_uuid: nil, identifier: "genesis", user_uuid: nil},
                  {"only one must be present", [validation: :only_one_required]}}
               ]
    end

    test "prevents creation of a wallet without a user and an account" do
      params = %{user: nil, account: nil}
      {result, changeset} = :wallet |> params_for(params) |> Wallet.insert()

      assert result == :error

      assert changeset.errors ==
               [
                 {%{account_uuid: nil, identifier: "genesis", user_uuid: nil},
                  {"can't all be blank", [validation: :required_exclusive]}}
               ]
    end

    test "allows insert of a wallet with the same name than one for another account" do
      {:ok, account1} = :account |> params_for() |> Account.insert()
      {:ok, account2} = :account |> params_for() |> Account.insert()
      wallet1 = Account.get_primary_wallet(account1)
      wallet2 = Account.get_primary_wallet(account2)

      assert wallet1.name == wallet2.name
    end

    test "allows insert of a wallet with the same name than one for another user" do
      {:ok, user1} = :user |> params_for() |> User.insert()
      {:ok, user2} = :user |> params_for() |> User.insert()
      wallet1 = User.get_primary_wallet(user1)
      wallet2 = User.get_primary_wallet(user2)

      assert wallet1.name == wallet2.name
    end

    test "prevents creation of a wallet with the same name for the same account" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)
      {res, changeset} = Account.insert_wallet(account, wallet.name)

      assert res == :error
      assert changeset.errors == [unique_account_name: {"has already been taken", []}]
    end

    test "prevents creation of a wallet with the same name for the same user" do
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)
      {res, changeset} = User.insert_wallet(user, wallet.name)

      assert res == :error
      assert changeset.errors == [unique_user_name: {"has already been taken", []}]
    end
  end

  describe "get/1" do
    test "returns an existing wallet using an address" do
      :wallet
      |> params_for(%{address: "wallet_address1234"})
      |> Wallet.insert()

      wallet = Wallet.get("wallet_address1234")
      assert wallet.address == "wallet_address1234"
    end

    test "returns nil if the wallet address does not exist" do
      assert Wallet.get("nonexisting_address") == nil
    end
  end

  describe "get_genesis/0" do
    test "inserts the genesis address if not existing" do
      assert Wallet.get("genesis") == nil
      genesis = Wallet.get_genesis()
      assert Wallet.get("genesis") == genesis
    end

    test "returns the existing genesis address if present" do
      inserted_genesis = Wallet.get_genesis()
      genesis = Wallet.get_genesis()
      assert inserted_genesis == genesis
    end
  end
end
