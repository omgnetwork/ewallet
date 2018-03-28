defmodule EWalletDB.AccountValidatorTest do
  use EWalletDB.SchemaCase
  alias Ecto.UUID
  alias EWalletDB.Account
  import Ecto.Changeset
  import EWalletDB.AccountValidator

  describe "validate_parent_id/1" do
    test "returns valid if parent_id is not nil" do
      attrs = %{parent_id: UUID.generate()}

      changeset =
        %Account{}
        |> cast(attrs, [:parent_id])
        |> validate_parent_id()

      assert changeset.valid?
    end

    test "returns valid if parent_id is nil for master account" do
      attrs = %{parent_id: nil}

      changeset =
        get_or_insert_master_account()
        |> cast(attrs, [:parent_id])
        |> validate_parent_id()

      assert changeset.valid?
    end

    test "returns error if parent_id is nil" do
      attrs = %{parent_id: nil}

      changeset =
        %Account{}
        |> cast(attrs, [:parent_id])
        |> validate_parent_id()

      refute changeset.valid?
      assert changeset.errors == [{:parent_id, {"can't be blank", [validation: :required]}}]
    end
  end

  describe "validate_account_level/2" do
    test "returns valid if the account's parent is not at the given max child level" do
      account0 = Account.get_master_account()

      {:ok, account1} =
        :account
        |> params_for(%{parent: account0})
        |> Account.insert()

      changeset =
        %Account{}
        |> cast(%{parent_id: account1.id}, [:parent_id])
        |> validate_account_level(2) # account0 -> account1 so far, there's room for account2

      assert changeset.valid?
    end

    test "returns error if the account's parent is already at the given max child level" do
      account0 = Account.get_master_account()

      {:ok, account1} =
        :account
        |> params_for(%{parent: account0})
        |> Account.insert()

      changeset =
        %Account{}
        |> cast(%{parent_id: account1.id}, [:parent_id])
        |> validate_account_level(1)

      refute changeset.valid?
      assert changeset.errors ==
        [{:parent_id, {"is at the maximum child level", [validation: :account_level_limit]}}]
    end
  end
end
