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
end
