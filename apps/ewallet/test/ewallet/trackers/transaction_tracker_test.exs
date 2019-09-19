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
  alias EWalletDB.{BlockchainDepositWallet, Transaction}

  describe "start_link/1" do
    test "starts a new server" do
      transaction = insert(:blockchain_transaction)

      assert {:ok, pid} =
               TransactionTracker.start_link(%{
                 transaction: transaction,
                 transaction_type: :from_blockchain_to_ewallet
               })

      assert is_pid(pid)
      assert GenServer.stop(pid) == :ok
    end
  end

  describe "init/1" do
    test "inits with transaction" do
      transaction = insert(:blockchain_transaction)

      assert TransactionTracker.init(%{
               transaction: transaction,
               transaction_type: :from_blockchain_to_ewallet
             }) ==
               {:ok,
                %{
                  transaction: transaction,
                  transaction_type: :from_blockchain_to_ewallet,
                  registry: nil
                }}
    end
  end

  describe "handle_cast/2 with :confirmations_count" do
    test "handles confirmations count when lower than minimum" do
      transaction = insert(:blockchain_transaction)

      assert {:ok, pid} =
               TransactionTracker.start_link(%{
                 transaction: transaction,
                 transaction_type: :from_blockchain_to_ewallet
               })

      :ok = GenServer.cast(pid, {:confirmations_count, transaction.blockchain_tx_hash, 2, 1})

      %{transaction: transaction, transaction_type: :from_blockchain_to_ewallet} =
        :sys.get_state(pid)

      assert %{confirmations_count: 2, status: "pending_confirmations"} = transaction

      assert GenServer.stop(pid) == :ok
    end

    test "handles confirmations count when higher than minimum" do
      transaction = insert(:blockchain_transaction)

      assert {:ok, pid} =
               TransactionTracker.start_link(%{
                 transaction: transaction,
                 transaction_type: :from_blockchain_to_ewallet
               })

      :ok = GenServer.cast(pid, {:confirmations_count, transaction.blockchain_tx_hash, 12, 1})

      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, _, _, _} ->
          transaction = Transaction.get(transaction.id)
          assert %{confirmations_count: 12, status: "confirmed"} = transaction
      end

      refute Process.alive?(pid)
    end

    test "recalculates the deposit wallet's balances when higher than minimum" do
      deposit_wallet = insert(:blockchain_deposit_wallet)

      # The initial balance can be anything except 123
      # which the blockchain dumb adapter always return.
      balance =
        insert(:blockchain_deposit_wallet_balance,
          blockchain_deposit_wallet: deposit_wallet,
          amount: 100
        )

      transaction =
        insert(
          :blockchain_transaction,
          to_blockchain_address: deposit_wallet.address,
          from_token: balance.token,
          to_token: balance.token
        )

      {:ok, pid} =
        TransactionTracker.start_link(%{
          transaction: transaction,
          transaction_type: :from_blockchain_to_ledger
        })

      :ok = GenServer.cast(pid, {:confirmations_count, transaction.blockchain_tx_hash, 12, 1})

      # Wait until the tracker winds down, reload the balances and assert for the new amount
      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, _, _, _} ->
          new_balance =
            deposit_wallet
            |> BlockchainDepositWallet.reload_balances()
            |> Map.fetch!(:balances)
            |> Enum.find(fn b -> b.uuid == balance.uuid end)

          # The balance is retrieved from the blockchain adapter, in which case
          # the dumb adapter is always returning 123.
          assert new_balance.amount == 123
      after
        5000 -> refute true
      end
    end

    test "handles invalid tx_hash" do
      transaction = insert(:blockchain_transaction)

      assert {:ok, pid} =
               TransactionTracker.start_link(%{
                 transaction: transaction,
                 transaction_type: :from_blockchain_to_ewallet
               })

      assert capture_log(fn ->
               :ok = GenServer.cast(pid, {:confirmations_count, "fake", 12, 1})
             end) =~ "The receipt has a mismatched hash"

      %{transaction: transaction, transaction_type: :from_blockchain_to_ewallet} =
        :sys.get_state(pid)

      assert %{confirmations_count: nil, status: "pending"} = transaction

      assert GenServer.stop(pid) == :ok
    end
  end
end
