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

  alias EWalletDB.{
    BlockchainTransaction,
    BlockchainState,
    BlockchainWallet,
    BlockchainTransactionState,
    TransactionState
  }

  describe "start_all_pending/0" do
    test "restarts trackers for all pending transaction" do
      identifier = BlockchainHelper.rootchain_identifier()

      hot_wallet = BlockchainWallet.get_primary_hot_wallet(identifier)

      blockchain_transaction_1 =
        insert(:blockchain_transaction_rootchain, status: BlockchainTransactionState.submitted())

      blockchain_transaction_2 =
        insert(:blockchain_transaction_rootchain,
          status: BlockchainTransactionState.pending_confirmations()
        )

      blockchain_transaction_3 =
        insert(:blockchain_transaction_rootchain, status: BlockchainTransactionState.confirmed())

      blockchain_transaction_4 =
        insert(:blockchain_transaction_rootchain, status: BlockchainTransactionState.failed())

      insert(:transaction_with_blockchain,
        blockchain_transaction: blockchain_transaction_1,
        from_blockchain_address: hot_wallet.address
      )

      insert(:transaction_with_blockchain,
        blockchain_transaction: blockchain_transaction_2,
        from_blockchain_address: hot_wallet.address
      )

      insert(:transaction_with_blockchain,
        blockchain_transaction: blockchain_transaction_3,
        from_blockchain_address: hot_wallet.address
      )

      insert(:transaction_with_blockchain,
        blockchain_transaction: blockchain_transaction_4,
        from_blockchain_address: hot_wallet.address
      )

      # Fast forward the blockchain manually to have the transactions confirmed.
      BlockchainState.update(identifier, 20)

      started_trackers = TransactionTracker.start_all_pending()

      assert length(started_trackers) == 2

      Enum.each(started_trackers, fn {res, pid} ->
        assert res == :ok
        assert is_pid(pid)
        ref = Process.monitor(pid)

        receive do
          {:DOWN, ^ref, _, ^pid, _} -> :ok
        end

        refute Process.alive?(pid)

        assert BlockchainTransaction.get_by(uuid: blockchain_transaction_1.uuid).status ==
                 BlockchainTransactionState.confirmed()

        assert BlockchainTransaction.get_by(uuid: blockchain_transaction_2.uuid).status ==
                 BlockchainTransactionState.confirmed()
      end)
    end
  end

  describe "start/1" do
    test "starts a new BlockchainTransactionTracker" do
      blockchain_transaction = insert(:blockchain_transaction_rootchain)

      transaction =
        insert(:transaction_with_blockchain, blockchain_transaction: blockchain_transaction)

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
