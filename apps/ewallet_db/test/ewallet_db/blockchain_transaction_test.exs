# Copyright 2018-2019 OmiseGO Pte Ltd
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

defmodule EWalletDB.BlockchainTransactionTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias ActivityLogger.System
  alias Ecto.Changeset
  alias EWalletDB.BlockchainTransaction

  describe "BlockchainTransaction factory" do
    test_has_valid_factory(BlockchainTransaction)
  end

  describe "state_changeset/4" do
    test "returns a changeset with casted fields" do
      res =
        BlockchainTransaction.state_changeset(
          %BlockchainTransaction{},
          %{
            "block_number" => 1,
            "originator" => %System{}
          },
          [:block_number],
          [:block_number]
        )

      assert %Changeset{} = res
      assert res.errors == []
    end

    test "returns an error when a required field is missing" do
      res =
        BlockchainTransaction.state_changeset(
          %BlockchainTransaction{},
          %{
            "originator" => %System{}
          },
          [:block_number],
          [:block_number]
        )

      assert %Changeset{} = res
      assert res.errors == [block_number: {"can't be blank", [validation: :required]}]
    end

    test "returns an error when the given status is not a valid status" do
      res =
        BlockchainTransaction.state_changeset(
          %BlockchainTransaction{},
          %{
            "status" => "fake",
            "originator" => %System{}
          },
          [:status],
          []
        )

      assert %Changeset{} = res
      assert res.errors == [status: {"is invalid", [validation: :inclusion]}]
    end

    test "returns an error if block_number is updated" do
      res =
        :blockchain_transaction
        |> insert(%{block_number: 1})
        |> BlockchainTransaction.state_changeset(
          %{
            "block_number" => 2,
            "originator" => %System{}
          },
          [:block_number],
          [:block_number]
        )

      assert %Changeset{} = res
      assert res.errors == [block_number: {"can't be changed", []}]
    end

    test "returns an error if confirmed_at_block_number is updated" do
      res =
        :blockchain_transaction
        |> insert(%{confirmed_at_block_number: 1})
        |> BlockchainTransaction.state_changeset(
          %{
            "confirmed_at_block_number" => 2,
            "originator" => %System{}
          },
          [:confirmed_at_block_number],
          [:confirmed_at_block_number]
        )

      assert %Changeset{} = res
      assert res.errors == [confirmed_at_block_number: {"can't be changed", []}]
    end
  end

  describe "get_last_block_number/1" do
    test "returns the last known block number for the given rootchain identifier" do
      identifier = "ethereum"
      insert(:blockchain_transaction, rootchain_identifier: identifier, block_number: 230)
      insert(:blockchain_transaction, rootchain_identifier: identifier, block_number: 123)

      block_number = BlockchainTransaction.get_last_block_number(identifier)
      assert block_number == 230
    end
  end

  describe "insert/1" do
    test_insert_generate_uuid(BlockchainTransaction, :uuid)
    test_insert_generate_timestamps(BlockchainTransaction)
    test_insert_prevent_blank(BlockchainTransaction, :rootchain_identifier)
    test_insert_prevent_blank(BlockchainTransaction, :gas_price)
    test_insert_prevent_blank(BlockchainTransaction, :gas_limit)
    test_insert_prevent_duplicate(BlockchainTransaction, :hash)

    test "returns an error when passing invalid arguments" do
      {res, changeset} = %{originator: %System{}} |> BlockchainTransaction.insert()

      assert res == :error

      assert changeset.errors == [
               {:hash, {"can't be blank", [validation: :required]}},
               {:rootchain_identifier, {"can't be blank", [validation: :required]}},
               {:gas_price, {"can't be blank", [validation: :required]}},
               {:gas_limit, {"can't be blank", [validation: :required]}}
             ]
    end
  end
end
