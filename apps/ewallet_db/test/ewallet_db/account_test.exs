defmodule EWalletDB.AccountTest do
  use EWalletDB.SchemaCase
  alias Ecto.UUID
  alias EWalletDB.Account

  describe "Account factory" do
    test_has_valid_factory Account
  end

  describe "Account.insert/1" do
    test_insert_generate_uuid Account, :id
    test_insert_generate_timestamps Account
    test_insert_prevent_blank Account, :name
    test_insert_prevent_duplicate Account, :name

    test "inserts a non-master account by default" do
      {:ok, account} = :account |> params_for() |> Account.insert
      assert account.master == false
    end

    test "inserts primary/burn balances for the account" do
      {:ok, account} = :account |> params_for() |> Account.insert
      primary = Account.get_primary_balance(account)
      burn = Account.get_default_burn_balance(account)

      assert primary != nil
      assert burn != nil
      assert length(account.balances) == 2
    end
  end

  describe "get/1" do
    test "accepts a uuid" do
      {:ok, account} = :account |> params_for() |> Account.insert
      result = Account.get(account.id)

      assert result.id == account.id
    end

    test "returns nil if the given uuid is invalid" do
      assert Account.get("not_a_uuid") == nil
    end

    test "returns nil if the account with the given uuid is not found" do
      assert Account.get(UUID.generate()) == nil
    end
  end

  describe "get/2" do
    test "accepts a uuid and preload" do
      {:ok, account} = :account |> params_for() |> Account.insert
      result = Account.get(account.id, preload: :balances)

      assert result.id == account.id
      assert Ecto.assoc_loaded?(result.balances)
    end
  end

  describe "get_by_name/1" do
    test "accepts a non-empty string" do
      {:ok, account} = :account |> params_for() |> Account.insert
      result = Account.get_by_name(account.name)

      assert result.id == account.id
      assert result.name == account.name
    end

    test "returns nil if the given name is nil" do
      assert Account.get(nil) == nil
    end

    test "returns nil if the given name is empty" do
      assert Account.get("") == nil
    end

    test "returns nil if the account with the given name is not found" do
      assert Account.get("not_an_account") == nil
    end
  end

  describe "get_master_account/1" do
    test "returns the master account" do
      {:ok, inserted1} = :account |> params_for(master: true) |> Account.insert
      {:ok, _} = :account |> params_for() |> Account.insert
      account = Account.get_master_account(true)

      assert account == inserted1
      assert account.master == true
    end
  end

  describe "get_master_account/0" do
    test "returns the master account without balances" do
      {:ok, inserted1} = :account |> params_for(master: true) |> Account.insert
      {:ok, _} = :account |> params_for() |> Account.insert
      account = Account.get_master_account()
      balances = account.balances

      assert account.id == inserted1.id
      assert %Ecto.Association.NotLoaded{} = balances
      assert account.master == true
    end
  end

  describe "get_primary_balance/1" do
    test "returns the primary balance" do
      {:ok, inserted} = :account |> params_for() |> Account.insert
      balance = Account.get_primary_balance(inserted)

      inserted.name
      |> Account.get_by_name()
      |> Repo.preload([:balances])

      assert balance != nil
      assert balance.name == "primary"
      assert balance.identifier == "primary"
    end
  end

  describe "get_default_burn_balance/1" do
    test "returns the burn balance" do
      {:ok, inserted} = :account |> params_for() |> Account.insert
      balance = Account.get_default_burn_balance(inserted)

      inserted.name
      |> Account.get_by_name()
      |> Repo.preload([:balances])

      assert balance != nil
      assert balance.name == "burn"
      assert balance.identifier == "burn"
    end
  end
end
