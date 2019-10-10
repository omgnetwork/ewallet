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

defmodule EWallet.TransactionTrackerTest do
  use EWallet.DBCase, async: false
  import EWalletDB.Factory

  alias EWallet.{BlockchainHelper, TransactionTracker}
  alias EWalletDB.{BlockchainWallet, BlockchainTransactionState, TransactionState}

  describe "start_all_pending/0" do
    test "restarts trackers for all pending transaction"
  end

  describe "start/1" do
    test "starts a new BlockchainTransactionTracker" do
      transaction = insert(:blockchain_transaction_rootchain)
      assert {:ok, pid} = TransactionTracker.start(transaction)

      assert is_pid(pid)
      assert GenServer.stop(pid) == :ok
    end
  end

  describe "on_confirmed/1" do
    test "process the confirmed transaction" do
      rootchain_identifier = BlockchainHelper.rootchain_identifier()
      hw_address = BlockchainWallet.get_primary_hot_wallet(rootchain_identifier).address

      blockchain_transaction =
        insert(:blockchain_transaction_rootchain, status: BlockchainTransactionState.confirmed())

      insert(:transaction_with_blockchain, %{
        blockchain_transaction: blockchain_transaction,
        to_blockchain_address: hw_address
      })

      assert {:ok, updated_tx} = TransactionTracker.on_confirmed(blockchain_transaction)
      assert updated_tx.status == TransactionState.confirmed()
    end
  end
end
