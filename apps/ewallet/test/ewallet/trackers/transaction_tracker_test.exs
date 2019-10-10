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
  import ExUnit.CaptureLog
  alias EWallet.TransactionTracker
  alias EWalletDB.{Transaction, TransactionState}

  describe "start/1" do
    test "starts a new server" do
      transaction = insert(:transaction_with_blockchain)

      assert {:ok, pid} = TransactionTracker.start(transaction, :from_blockchain_to_ewallet)
      assert is_pid(pid)
      assert GenServer.stop(pid) == :ok
    end
  end

  describe "handle_cast/2 with :confirmations_count" do
    test "handles confirmations count when lower than minimum" do
      transaction = insert(:transaction_with_blockchain)
      assert {:ok, pid} = TransactionTracker.start(transaction, :from_blockchain_to_ewallet)

      :ok = GenServer.cast(pid, {:confirmations_count, transaction.blockchain_tx_hash, 2, 1})

      # A low confirmations count does not stop the tracker so we stop it manually.
      assert GenServer.stop(pid) == :ok

      # Since the stop is synchronous, we can now safely assert the latest state
      transaction = Transaction.get(transaction.id)
      assert transaction.confirmations_count == 2
      assert transaction.status == TransactionState.pending_confirmations()
    end

    test "handles confirmations count when higher than minimum" do
      transaction = insert(:transaction_with_blockchain)
      assert {:ok, pid} = TransactionTracker.start(transaction, :from_blockchain_to_ewallet)

      :ok = GenServer.cast(pid, {:confirmations_count, transaction.blockchain_tx_hash, 12, 1})
      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, _, _, _} ->
          transaction = Transaction.get(transaction.id)
          assert transaction.confirmations_count == 12
          assert transaction.status == TransactionState.confirmed()
      end

      refute Process.alive?(pid)
    end

    test "logs a message about mismatched hash" do
      transaction = insert(:transaction_with_blockchain)
      {:ok, pid} = TransactionTracker.start(transaction, :from_blockchain_to_ewallet)

      assert capture_log(fn ->
               :ok = GenServer.cast(pid, {:confirmations_count, "fake", 12, 1})
               _ = Process.sleep(100)
             end) =~ "The receipt has a mismatched hash"

      # A mismatch hash does not stop the tracker so we stop it manually.
      assert GenServer.stop(pid)

      # Since the stop is synchronous, we can now safely assert the latest state
      transaction = Transaction.get(transaction.id)
      assert transaction.confirmations_count == nil
      assert transaction.status == TransactionState.pending()
    end
  end
end
