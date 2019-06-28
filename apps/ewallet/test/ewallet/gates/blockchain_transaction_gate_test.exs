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
  alias EWallet.{BlockchainTransactionGate, TransactionRegistry}
  alias EWalletDB.BlockchainWallet
  alias ActivityLogger.System
  alias Utils.Helpers.Crypto
  alias Ecto.UUID

  describe "create/2" do
    test "submits a transaction to the blockchain subapp (hot wallet to blockchain address)",
         meta do
      # TODO: switch to using the seeded Ethereum address
      admin = insert(:admin, global_role: "super_admin")
      primary_blockchain_token = insert(:token, blockchain_address: "0x0000000000000000000000000000000000000000")
      hot_wallet = BlockchainWallet.get_primary_hot_wallet()

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "from_address" => hot_wallet.address,
        "to_address" => Crypto.fake_eth_address(),
        "token_id" => primary_blockchain_token.id,
        "amount" => 1,
        "originator" => %System{}
      }

      {:ok, transaction} = BlockchainTransactionGate.create(admin, attrs, [true, true])

      assert transaction.status == "submitted"
      assert transaction.type == "external"
      assert transaction.blockchain_identifier == "ethereum"
      assert transaction.confirmations_count == nil

      {:ok, res} = TransactionRegistry.lookup(transaction.uuid)
      assert %{tracker: EWallet.TransactionTracker, pid: pid} = res

      {:ok, res} = meta[:adapter].lookup_listener(transaction.blockchain_tx_hash)
      assert %{listener: _, pid: blockchain_listener_pid} = res

      :sys.get_state(pid)
      :sys.get_state(blockchain_listener_pid)
    end

    test "returns an error when trying to exchange" do
      admin = insert(:admin, global_role: "super_admin")
      primary_blockchain_token = insert(:token, blockchain_address: "0x0000000000000000000000000000000000000000")
      token = insert(:token)
      hot_wallet = BlockchainWallet.get_primary_hot_wallet()

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "from_address" => hot_wallet.address,
        "to_address" => Crypto.fake_eth_address(),
        "from_token_id" => primary_blockchain_token.id,
        "to_token_id" => token.id,
        "amount" => 1,
        "originator" => %System{}
      }

      {:error, :blockchain_exchange_not_allowed} =
        BlockchainTransactionGate.create(admin, attrs, [true, true])
    end

    test "returns an error when amounts are not valid" do
      admin = insert(:admin, global_role: "super_admin")
      primary_blockchain_token = insert(:token, blockchain_address: "0x0000000000000000000000000000000000000000")
      hot_wallet = BlockchainWallet.get_primary_hot_wallet()

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "from_address" => hot_wallet.address,
        "to_address" => Crypto.fake_eth_address(),
        "token_id" => primary_blockchain_token.id,
        "from_amount" => 1,
        "to_amount" => 2,
        "originator" => %System{}
      }

      {:error, :amounts_missing_or_invalid} =
        BlockchainTransactionGate.create(admin, attrs, [true, true])
    end

    test "returns an error when the hot wallet doesn't have enough funds" do
      admin = insert(:admin, global_role: "super_admin")
      primary_blockchain_token = insert(:token, blockchain_address: "0x0000000000000000000000000000000000000000")
      hot_wallet = BlockchainWallet.get_primary_hot_wallet()

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "from_address" => hot_wallet.address,
        "to_address" => Crypto.fake_eth_address(),
        "token_id" => primary_blockchain_token.id,
        "amount" => 125,
        "originator" => %System{}
      }

      {:error, :insufficient_funds} = BlockchainTransactionGate.create(admin, attrs, [true, true])
    end

    test "returns an error if the token is not a blockchain token" do
      admin = insert(:admin, global_role: "super_admin")
      token = insert(:token)
      hot_wallet = BlockchainWallet.get_primary_hot_wallet()

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "from_address" => hot_wallet.address,
        "to_address" => Crypto.fake_eth_address(),
        "token_id" => token.id,
        "amount" => 1,
        "originator" => %System{}
      }

      {:error, :token_not_blockchain_enabled} =
        BlockchainTransactionGate.create(admin, attrs, [true, true])
    end
  end
end
