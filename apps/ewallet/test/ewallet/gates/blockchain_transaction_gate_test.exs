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

defmodule EWallet.BlockchainTransactionGateTest do
  use EWallet.DBCase, async: false
  import EWalletDB.Factory
  alias EWallet.{BlockchainHelper, BlockchainTransactionGate, TransactionRegistry}
  alias EWalletDB.{BlockchainWallet, Transaction, TransactionState}
  alias ActivityLogger.System
  alias Utils.Helpers.Crypto
  alias Ecto.UUID

  describe "create/2" do
    test "submits a transaction to the blockchain subapp (hot wallet to blockchain address)",
         meta do
      # TODO: switch to using the seeded Ethereum address
      admin = insert(:admin, global_role: "super_admin")

      primary_blockchain_token =
        insert(:token, blockchain_address: "0x0000000000000000000000000000000000000000")

      identifier = BlockchainHelper.identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(identifier)

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "from_address" => hot_wallet.address,
        "to_address" => Crypto.fake_eth_address(),
        "token_id" => primary_blockchain_token.id,
        "amount" => 1,
        "originator" => %System{}
      }

      {:ok, transaction} = BlockchainTransactionGate.create(admin, attrs, {true, true})

      assert transaction.status == TransactionState.blockchain_submitted()
      assert transaction.type == Transaction.external()
      assert transaction.blockchain_identifier == identifier
      assert transaction.confirmations_count == nil

      {:ok, res} = TransactionRegistry.lookup(transaction.uuid)
      assert %{tracker: EWallet.TransactionTracker, pid: pid} = res

      {:ok, res} = meta[:adapter].lookup_listener(transaction.blockchain_tx_hash)
      assert %{listener: _, pid: blockchain_listener_pid} = res

      assert Process.alive?(pid)
      assert Process.alive?(blockchain_listener_pid)

      # Turn off the listeners before exiting so it does not try
      # to update the transactions after the test is done.
      on_exit(fn ->
        :ok = GenServer.stop(pid)
        :ok = GenServer.stop(blockchain_listener_pid)
      end)
    end

    test "returns an error when trying to exchange" do
      admin = insert(:admin, global_role: "super_admin")

      primary_blockchain_token =
        insert(:token, blockchain_address: "0x0000000000000000000000000000000000000000")

      token = insert(:token)
      identifier = BlockchainHelper.identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(identifier)

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "from_address" => hot_wallet.address,
        "to_address" => Crypto.fake_eth_address(),
        "from_token_id" => primary_blockchain_token.id,
        "to_token_id" => token.id,
        "amount" => 1,
        "originator" => %System{}
      }

      assert {:error, :blockchain_exchange_not_allowed} ==
        BlockchainTransactionGate.create(admin, attrs, {true, true})
    end

    test "returns an error when amounts are not valid" do
      admin = insert(:admin, global_role: "super_admin")

      primary_blockchain_token =
        insert(:token, blockchain_address: "0x0000000000000000000000000000000000000000")

      identifier = BlockchainHelper.identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(identifier)

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "from_address" => hot_wallet.address,
        "to_address" => Crypto.fake_eth_address(),
        "token_id" => primary_blockchain_token.id,
        "from_amount" => 1,
        "to_amount" => 2,
        "originator" => %System{}
      }

      assert {:error, :amounts_missing_or_invalid} ==
        BlockchainTransactionGate.create(admin, attrs, {true, true})
    end

    test "returns an error when the hot wallet doesn't have enough funds" do
      admin = insert(:admin, global_role: "super_admin")

      primary_blockchain_token =
        insert(:token, blockchain_address: "0x0000000000000000000000000000000000000000")

      identifier = BlockchainHelper.identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(identifier)

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "from_address" => hot_wallet.address,
        "to_address" => Crypto.fake_eth_address(),
        "token_id" => primary_blockchain_token.id,
        "amount" => 125,
        "originator" => %System{}
      }

      assert {:error, :insufficient_funds} == BlockchainTransactionGate.create(admin, attrs, {true, true})
    end

    test "returns an error if the token is not a blockchain token" do
      admin = insert(:admin, global_role: "super_admin")
      token = insert(:token)

      identifier = BlockchainHelper.identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(identifier)

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "from_address" => hot_wallet.address,
        "to_address" => Crypto.fake_eth_address(),
        "token_id" => token.id,
        "amount" => 1,
        "originator" => %System{}
      }

      assert {:error, :token_not_blockchain_enabled} ==
        BlockchainTransactionGate.create(admin, attrs, {true, true})
    end
  end

  describe "create_from_tracker/2" do
    test "creates the local transaction and starts tracking the blockchain transaction"
  end

  describe "get_or_insert/1" do
    test "returns a newly inserted local transaction if the idempotency_token is new"
    test "returns the existing local transaction if the idempotency_token already exists"
    test "returns :idempotency_token if the idempotency_token is not given"
  end

  describe "blockchain_addresses?/1" do
    test "returns a list of booleans indicating whether each given address is a blockchain address"
  end

  describe "handle_local_insert/1" do
    test "transitions the transaction to confirmed if transaction.to is nil"
    test "processes the transaction with BlockchainLocalTransactionGate if transaction.to is not nil"
  end
end
