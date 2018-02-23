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
      refute Account.master?(account)
    end

    test "prevents inserting an account without a parent" do
      {res, changeset} =
        :account
        |> params_for(parent: nil)
        |> Account.insert

      assert res == :error
      assert changeset.errors ==
        [{:parent_id, {"can't be blank", [validation: :required]}}]
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

    test "returns :invalid_parameter error if the given id is not a uuid" do
      assert Account.get("not_a_uuid") ==
        {:error, :invalid_parameter, ~s/Expected a UUID, given "not_a_uuid"/}
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
      result  = Account.get_master_account()

      assert result.id == get_or_insert_master_account().id
      assert %Ecto.Association.NotLoaded{} = result.balances
      assert Account.master?(result)
    end

    test "returns the master account with balances if preload is given" do
      result = Account.get_master_account(preload: :balances)

      assert result.id == get_or_insert_master_account().id
      assert Account.master?(result)
    end
  end

  describe "get_primary_balance/1" do
    test "returns the primary balance" do
      {:ok, inserted} = :account |> params_for() |> Account.insert
      balance = Account.get_primary_balance(inserted)

      [name: inserted.name]
      |> Account.get_by()
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

      [name: inserted.name]
      |> Account.get_by()
      |> Repo.preload([:balances])

      assert balance != nil
      assert balance.name == "burn"
      assert balance.identifier == "burn"
    end
  end
end
