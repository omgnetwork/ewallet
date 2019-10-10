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
  alias EWalletDB.{BlockchainTransaction, BlockchainTransactionState}

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
        :blockchain_transaction_rootchain
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
        :blockchain_transaction_rootchain
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

      insert(:blockchain_transaction_rootchain,
        rootchain_identifier: identifier,
        block_number: 230
      )

      insert(:blockchain_transaction_rootchain,
        rootchain_identifier: identifier,
        block_number: 123
      )

      block_number = BlockchainTransaction.get_last_block_number(identifier)
      assert block_number == 230
    end
  end

  describe "insert_outgoing_rootchain/1" do
    test_insert_ok(
      BlockchainTransaction,
      :hash,
      "0x0",
      &BlockchainTransaction.insert_outgoing_rootchain/1,
      :blockchain_transaction_rootchain
    )

    test_insert_ok(
      BlockchainTransaction,
      :rootchain_identifier,
      "ethereum",
      &BlockchainTransaction.insert_outgoing_rootchain/1,
      :blockchain_transaction_rootchain
    )

    test_insert_ok(
      BlockchainTransaction,
      :status,
      BlockchainTransactionState.submitted(),
      &BlockchainTransaction.insert_outgoing_rootchain/1,
      :blockchain_transaction_rootchain
    )

    test_insert_ok(
      BlockchainTransaction,
      :gas_price,
      10,
      &BlockchainTransaction.insert_outgoing_rootchain/1,
      :blockchain_transaction_rootchain
    )

    test_insert_ok(
      BlockchainTransaction,
      :gas_limit,
      10,
      &BlockchainTransaction.insert_outgoing_rootchain/1,
      :blockchain_transaction_rootchain
    )

    test_insert_ok(
      BlockchainTransaction,
      :metadata,
      %{"some" => "thing"},
      &BlockchainTransaction.insert_outgoing_rootchain/1,
      :blockchain_transaction_rootchain
    )

    test_insert_generate_uuid(
      BlockchainTransaction,
      :uuid,
      &BlockchainTransaction.insert_outgoing_rootchain/1,
      :blockchain_transaction_rootchain
    )

    test_insert_generate_timestamps(
      BlockchainTransaction,
      &BlockchainTransaction.insert_outgoing_rootchain/1,
      :blockchain_transaction_rootchain
    )

    test_insert_prevent_blank(
      BlockchainTransaction,
      :rootchain_identifier,
      &BlockchainTransaction.insert_outgoing_rootchain/1,
      :blockchain_transaction_rootchain
    )

    test_insert_prevent_blank(
      BlockchainTransaction,
      :gas_price,
      &BlockchainTransaction.insert_outgoing_rootchain/1,
      :blockchain_transaction_rootchain
    )

    test_insert_prevent_blank(
      BlockchainTransaction,
      :gas_limit,
      &BlockchainTransaction.insert_outgoing_rootchain/1,
      :blockchain_transaction_rootchain
    )

    test_insert_prevent_blank(
      BlockchainTransaction,
      :hash,
      &BlockchainTransaction.insert_outgoing_rootchain/1,
      :blockchain_transaction_rootchain
    )

    test_insert_prevent_duplicate(
      BlockchainTransaction,
      :hash,
      "0x0",
      &BlockchainTransaction.insert_outgoing_rootchain/1,
      :blockchain_transaction_rootchain
    )
  end

  describe "insert_incoming_rootchain/1" do
    test_insert_ok(
      BlockchainTransaction,
      :hash,
      "0x0",
      &BlockchainTransaction.insert_incoming_rootchain/1,
      :blockchain_transaction_rootchain
    )

    test_insert_ok(
      BlockchainTransaction,
      :rootchain_identifier,
      "ethereum",
      &BlockchainTransaction.insert_incoming_rootchain/1,
      :blockchain_transaction_rootchain
    )

    test_insert_ok(
      BlockchainTransaction,
      :status,
      BlockchainTransactionState.submitted(),
      &BlockchainTransaction.insert_incoming_rootchain/1,
      :blockchain_transaction_rootchain
    )

    test_insert_ok(
      BlockchainTransaction,
      :metadata,
      %{"some" => "thing"},
      &BlockchainTransaction.insert_incoming_rootchain/1,
      :blockchain_transaction_rootchain
    )

    test_insert_generate_uuid(
      BlockchainTransaction,
      :uuid,
      &BlockchainTransaction.insert_incoming_rootchain/1,
      :blockchain_transaction_rootchain
    )

    test_insert_generate_timestamps(
      BlockchainTransaction,
      &BlockchainTransaction.insert_incoming_rootchain/1,
      :blockchain_transaction_rootchain
    )

    test_insert_prevent_blank(
      BlockchainTransaction,
      :rootchain_identifier,
      &BlockchainTransaction.insert_incoming_rootchain/1,
      :blockchain_transaction_rootchain
    )

    test_insert_prevent_blank(
      BlockchainTransaction,
      :block_number,
      &BlockchainTransaction.insert_incoming_rootchain/1,
      :blockchain_transaction_rootchain
    )

    test_insert_prevent_blank(
      BlockchainTransaction,
      :hash,
      &BlockchainTransaction.insert_incoming_rootchain/1,
      :blockchain_transaction_rootchain
    )

    test_insert_prevent_duplicate(
      BlockchainTransaction,
      :hash,
      "0x0",
      &BlockchainTransaction.insert_incoming_rootchain/1,
      :blockchain_transaction_rootchain
    )
  end

  describe "insert_childchain/1" do
    test_insert_ok(
      BlockchainTransaction,
      :hash,
      "0x0",
      &BlockchainTransaction.insert_childchain/1,
      :blockchain_transaction_childchain
    )

    test_insert_ok(
      BlockchainTransaction,
      :rootchain_identifier,
      "ethereum",
      &BlockchainTransaction.insert_childchain/1,
      :blockchain_transaction_childchain
    )

    test_insert_ok(
      BlockchainTransaction,
      :childchain_identifier,
      "omisego_network",
      &BlockchainTransaction.insert_childchain/1,
      :blockchain_transaction_childchain
    )

    test_insert_ok(
      BlockchainTransaction,
      :status,
      BlockchainTransactionState.submitted(),
      &BlockchainTransaction.insert_childchain/1,
      :blockchain_transaction_childchain
    )

    test_insert_ok(
      BlockchainTransaction,
      :metadata,
      %{"some" => "thing"},
      &BlockchainTransaction.insert_childchain/1,
      :blockchain_transaction_childchain
    )

    test_insert_generate_uuid(
      BlockchainTransaction,
      :uuid,
      &BlockchainTransaction.insert_childchain/1,
      :blockchain_transaction_childchain
    )

    test_insert_generate_timestamps(
      BlockchainTransaction,
      &BlockchainTransaction.insert_childchain/1,
      :blockchain_transaction_childchain
    )

    test_insert_prevent_blank(
      BlockchainTransaction,
      :rootchain_identifier,
      &BlockchainTransaction.insert_childchain/1,
      :blockchain_transaction_childchain
    )

    test_insert_prevent_blank(
      BlockchainTransaction,
      :childchain_identifier,
      &BlockchainTransaction.insert_childchain/1,
      :blockchain_transaction_childchain
    )

    test_insert_prevent_blank(
      BlockchainTransaction,
      :hash,
      &BlockchainTransaction.insert_childchain/1,
      :blockchain_transaction_childchain
    )

    test_insert_prevent_duplicate(
      BlockchainTransaction,
      :hash,
      "0x0",
      &BlockchainTransaction.insert_childchain/1,
      :blockchain_transaction_childchain
    )
  end
end
