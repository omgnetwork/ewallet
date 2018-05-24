defmodule EWalletDB.AccountTest do
  use EWalletDB.SchemaCase
  alias Ecto.UUID
  alias EWalletDB.Account

  describe "Account factory" do
    test_has_valid_factory(Account)
    test_encrypted_map_field(Account, "account", :encrypted_metadata)
  end

  describe "Account.insert/1" do
    test_insert_generate_uuid(Account, :uuid)
    test_insert_generate_external_id(Account, :id, "acc_")
    test_insert_generate_timestamps(Account)
    test_insert_prevent_blank(Account, :name)
    test_insert_prevent_duplicate(Account, :name)
    test_default_metadata_fields(Account, "account")

    test "inserts a non-master account by default" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      refute Account.master?(account)
    end

    test "prevents inserting an account without a parent" do
      {res, changeset} =
        :account
        |> params_for(parent: nil)
        |> Account.insert()

      assert res == :error

      assert Enum.member?(
               changeset.errors,
               {:parent_uuid, {"can't be blank", [validation: :required]}}
             )
    end

    test "inserts primary/burn wallets for the account" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      primary = Account.get_primary_wallet(account)
      burn = Account.get_default_burn_wallet(account)

      assert primary != nil
      assert burn != nil
      assert length(account.wallets) == 2
    end

    test "prevents inserting an account beyond 1 child level" do
      account0 = Account.get_master_account()

      {:ok, account1} =
        :account
        |> params_for(%{parent: account0})
        |> Account.insert()

      {res, changeset} =
        :account
        |> params_for(parent: account1)
        |> Account.insert()

      assert res == :error

      assert changeset.errors ==
               [
                 {:parent_uuid,
                  {"is at the maximum child level", [validation: :account_level_limit]}}
               ]
    end
  end

  describe "get/1" do
    test "accepts a uuid" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      result = Account.get(account.id)

      assert result.id == account.id
    end

    test "returns :invalid_parameter error if the given id is not a uuid" do
      assert Account.get("not_a_uuid") == nil
    end

    test "returns nil if the account with the given uuid is not found" do
      assert Account.get(UUID.generate()) == nil
    end
  end

  describe "get/2" do
    test "accepts a uuid and preload" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      result = Account.get(account.id, preload: :wallets)

      assert result.id == account.id
      assert Ecto.assoc_loaded?(result.wallets)
    end
  end

  describe "get_by_name/1" do
    test "accepts a non-empty string" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      result = Account.get_by(name: account.name)

      assert result.id == account.id
      assert result.name == account.name
    end

    test "returns nil if the account with the given name is not found" do
      assert Account.get_by(name: "not_an_account") == nil
    end
  end

  describe "get_master_account/1" do
    test "returns the master account" do
      result = Account.get_master_account()

      assert result.id == get_or_insert_master_account().id
      assert %Ecto.Association.NotLoaded{} = result.wallets
      assert Account.master?(result)
    end

    test "returns the master account with wallets if preload is given" do
      result = Account.get_master_account(preload: :wallets)

      assert result.id == get_or_insert_master_account().id
      assert Account.master?(result)
    end
  end

  describe "get_primary_wallet/1" do
    test "returns the primary wallet" do
      {:ok, inserted} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(inserted)

      [name: inserted.name]
      |> Account.get_by()
      |> Repo.preload([:wallets])

      assert wallet != nil
      assert wallet.name == "primary"
      assert wallet.identifier == "primary"
    end
  end

  describe "get_default_burn_wallet/1" do
    test "returns the burn wallet" do
      {:ok, inserted} = :account |> params_for() |> Account.insert()
      wallet = Account.get_default_burn_wallet(inserted)

      [name: inserted.name]
      |> Account.get_by()
      |> Repo.preload([:wallets])

      assert wallet != nil
      assert wallet.name == "burn"
      assert wallet.identifier == "burn"
    end
  end

  describe "get_depth/1" do
    test "returns 0 if the given account is the master account" do
      account = Account.get_master_account()
      assert Account.get_depth(account) == 0
    end

    test "returns 1 if the given account is directly below the master account" do
      account0 = Account.get_master_account()
      account1 = insert(:account, %{parent: account0})
      assert Account.get_depth(account1) == 1
    end

    test "returns 3 if the given account is 3 steps below the master account" do
      account0 = Account.get_master_account()
      account1 = insert(:account, %{parent: account0})
      account2 = insert(:account, %{parent: account1})
      account3 = insert(:account, %{parent: account2})
      assert Account.get_depth(account3) == 3
    end

    # Returning a value, e.g. 0, is unsafe since that would be assuming that
    # some arbitary account or value is the top level account. Safer to raise an error.
    test "raises an error if given nil" do
      assert_raise FunctionClauseError, fn ->
        Account.get_depth(nil)
      end
    end
  end
end
