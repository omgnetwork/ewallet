# Copyright 2018 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EWalletDB.AccountValidatorTest do
  use EWalletDB.SchemaCase, async: true
  import Ecto.Changeset
  import EWalletDB.{AccountValidator, Factory}
  alias Ecto.UUID
  alias EWalletDB.Account

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

  describe "validate_account_level/2 with top-level account" do
    test "returns a valid changeset if the given max child level is == 0" do
      changeset =
        %Account{}
        |> change()
        |> force_change(:parent_uuid, nil)
        |> validate_account_level(0)

      assert changeset.valid?
    end

    test "returns a valid changeset if the given max child level is > 0" do
      changeset =
        %Account{}
        |> change()
        |> force_change(:parent_uuid, nil)
        |> validate_account_level(1)

      assert changeset.valid?
    end

    test "returns a changeset error if the given max child level is < 0" do
      changeset =
        %Account{}
        |> change()
        |> force_change(:parent_uuid, nil)
        |> validate_account_level(-1)

      refute changeset.valid?
    end
  end

  describe "validate_account_level/2 with sub-level account" do
    test "returns valid if the account's parent is not at the given max child level" do
      account0 = Account.get_master_account()

      {:ok, account1} =
        :account
        |> params_for(%{parent: account0})
        |> Account.insert()

      # account0 -> account1 so far, there's room for account2
      changeset =
        %Account{}
        |> cast(%{parent_uuid: account1.uuid}, [:parent_uuid])
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
