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

defmodule EWallet.TransactionGate.ChildchainTest do
  use EWallet.DBCase, async: false
  import EWalletDB.Factory

  alias EWallet.{
    BlockchainHelper,
    BlockchainTransactionTracker,
    TransactionGate
  }

  alias EWalletDB.{BlockchainWallet, Transaction, TransactionState}
  alias Ecto.UUID
  alias ActivityLogger.System

  describe "deposit/2" do
    test "formats and forward attributes to the blockchain gate", meta do
      admin = insert(:admin, global_role: "super_admin")

      primary_blockchain_token =
        insert(:token,
          blockchain_status: "confirmed",
          blockchain_address: "0x0000000000000000000000000000000000000000"
        )

      rootchain_identifier = BlockchainHelper.rootchain_identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(rootchain_identifier)

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "address" => hot_wallet.address,
        "token_id" => primary_blockchain_token.id,
        "amount" => 1,
        "originator" => %System{}
      }

      {:ok, transaction} = TransactionGate.Childchain.deposit(admin, attrs)

      {:ok, vault_address} = BlockchainHelper.call(:get_childchain_eth_vault_address)

      assert transaction.status == TransactionState.blockchain_submitted()
      assert transaction.type == Transaction.deposit()
      assert transaction.blockchain_transaction.rootchain_identifier == rootchain_identifier
      assert transaction.blockchain_transaction.childchain_identifier == nil
      assert transaction.from_blockchain_address == hot_wallet.address
      assert transaction.to_blockchain_address == vault_address

      {:ok, pid} = BlockchainTransactionTracker.lookup(transaction.blockchain_transaction_uuid)

      {:ok, %{pid: blockchain_listener_pid}} =
        meta[:adapter].lookup_listener(transaction.blockchain_transaction.hash)

      # to update the transactions after the test is done.
      on_exit(fn ->
        :ok = GenServer.stop(pid)
        :ok = GenServer.stop(blockchain_listener_pid)
      end)
    end

    test "accepts a string amount", meta do
      admin = insert(:admin, global_role: "super_admin")

      primary_blockchain_token =
        insert(:token,
          blockchain_status: "confirmed",
          blockchain_address: "0x0000000000000000000000000000000000000000"
        )

      rootchain_identifier = BlockchainHelper.rootchain_identifier()
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(rootchain_identifier)

      attrs = %{
        "idempotency_token" => UUID.generate(),
        "address" => hot_wallet.address,
        "token_id" => primary_blockchain_token.id,
        "amount" => Integer.to_string(1),
        "originator" => %System{}
      }

      {:ok, transaction} = TransactionGate.Childchain.deposit(admin, attrs)

      {:ok, vault_address} = BlockchainHelper.call(:get_childchain_eth_vault_address)

      assert transaction.status == TransactionState.blockchain_submitted()
      assert transaction.type == Transaction.deposit()
      assert transaction.blockchain_transaction.rootchain_identifier == rootchain_identifier
      assert transaction.blockchain_transaction.childchain_identifier == nil
      assert transaction.from_blockchain_address == hot_wallet.address
      assert transaction.to_blockchain_address == vault_address

      {:ok, pid} = BlockchainTransactionTracker.lookup(transaction.blockchain_transaction_uuid)

      {:ok, %{pid: blockchain_listener_pid}} =
        meta[:adapter].lookup_listener(transaction.blockchain_transaction.hash)

      # to update the transactions after the test is done.
      on_exit(fn ->
        :ok = GenServer.stop(pid)
        :ok = GenServer.stop(blockchain_listener_pid)
      end)
    end
  end
end
