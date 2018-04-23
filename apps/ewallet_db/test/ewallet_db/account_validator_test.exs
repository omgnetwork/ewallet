defmodule EWalletDB.AccountValidatorTest do
  use EWalletDB.SchemaCase
  alias Ecto.UUID
  alias EWalletDB.Account
  import Ecto.Changeset
  import EWalletDB.AccountValidator

  describe "validate_parent_uuid/1" do
    test "returns valid if parent_uuid is not nil" do
      attrs = %{parent_uuid: UUID.generate()}

      changeset =
        %Account{}
        |> cast(attrs, [:parent_uuid])
        |> validate_parent_uuid()

      assert changeset.valid?
    end

    test "returns valid if parent_uuid is nil for master account" do
      attrs = %{parent_uuid: nil}

      changeset =
        get_or_insert_master_account()
        |> cast(attrs, [:parent_uuid])
        |> validate_parent_uuid()

      assert changeset.valid?
    end

    test "returns error if parent_uuid is nil" do
      attrs = %{parent_uuid: nil}

      changeset =
        %Account{}
        |> cast(attrs, [:parent_uuid])
        |> validate_parent_uuid()

      refute changeset.valid?
      assert changeset.errors == [{:parent_uuid, {"can't be blank", [validation: :required]}}]
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
        |> cast(%{parent_uuid: account1.uuid}, [:parent_uuid])
        # account0 -> account1 so far, there's room for account2
        |> validate_account_level(2)

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
        |> cast(%{parent_uuid: account1.uuid}, [:parent_uuid])
        |> validate_account_level(1)

      refute changeset.valid?

      assert changeset.errors ==
               [
                 {:parent_uuid,
                  {"is at the maximum child level", [validation: :account_level_limit]}}
               ]
    end
  end
end
