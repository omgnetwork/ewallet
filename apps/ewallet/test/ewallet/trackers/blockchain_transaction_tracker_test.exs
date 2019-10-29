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

defmodule EWallet.BlockchainTransactionTrackerTest do
  use EWallet.DBCase, async: false
  import EWalletDB.Factory
  import ExUnit.CaptureLog
  alias EWallet.{BlockchainHelper, BlockchainTransactionTracker, DummyTransactionTracker}
  alias EWalletDB.{BlockchainTransaction, BlockchainTransactionState}

  setup do
    {:ok, _} = DummyTransactionTracker.start_link()
    :ok
  end

  describe "start/1" do
    test "starts a new server" do
      transaction = insert(:blockchain_transaction_rootchain)

      assert {:ok, pid} = BlockchainTransactionTracker.start(transaction, DummyTransactionTracker)
      assert is_pid(pid)
      assert GenServer.stop(pid) == :ok
    end
  end

  describe "lookup/2" do
    test "lookup an exising tracker" do
      transaction_1 = insert(:blockchain_transaction_rootchain)
      transaction_2 = insert(:blockchain_transaction_rootchain)

      assert {:ok, pid_1} =
               BlockchainTransactionTracker.start(transaction_1, DummyTransactionTracker)

      assert {:ok, pid_2} =
               BlockchainTransactionTracker.start(transaction_2, DummyTransactionTracker)

      assert {:ok, pid_1} == BlockchainTransactionTracker.lookup(transaction_1.uuid)
      assert {:ok, pid_2} == BlockchainTransactionTracker.lookup(transaction_2.uuid)

      assert GenServer.stop(pid_1) == :ok
      assert GenServer.stop(pid_2) == :ok
    end

    test "returns an error not found when tracker is not found" do
      assert {:error, :not_found} == BlockchainTransactionTracker.lookup("fake")
    end
  end

  describe "handle_cast/2 with :confirmations_count" do
    test "handles confirmations count when lower than minimum" do
      transaction = insert(:blockchain_transaction_rootchain)
      assert {:ok, pid} = BlockchainTransactionTracker.start(transaction, DummyTransactionTracker)

      identifier = BlockchainHelper.rootchain_identifier()
      # Fast forward the blockchain manually to have the desired confirmation count.
      EWalletDB.BlockchainState.update(identifier, 1)

      :ok = GenServer.cast(pid, {:confirmations_count, transaction.hash, 1})

      # A low confirmations count does not stop the tracker so we stop it manually.
      assert GenServer.stop(pid) == :ok

      # Since the stop is synchronous, we can now safely assert the latest state
      transaction = BlockchainTransaction.get_by(uuid: transaction.uuid)

      assert transaction.confirmed_at_block_number == nil
      assert transaction.block_number == 1
      assert transaction.status == BlockchainTransactionState.pending_confirmations()
    end

    test "handles confirmations count when higher than minimum" do
      transaction = insert(:blockchain_transaction_rootchain)
      assert {:ok, pid} = BlockchainTransactionTracker.start(transaction, DummyTransactionTracker)

      identifier = BlockchainHelper.rootchain_identifier()
      # Fast forward the blockchain manually to have the desired confirmation count.
      EWalletDB.BlockchainState.update(identifier, 20)

      :ok = GenServer.cast(pid, {:confirmations_count, transaction.hash, 1})
      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, _, _, _} ->
          transaction = BlockchainTransaction.get_by(uuid: transaction.uuid)
          assert transaction.confirmed_at_block_number == 20
          assert transaction.status == BlockchainTransactionState.confirmed()

          # Asserting that the `on_confirmed/1` was called successfully for the given module
          assert DummyTransactionTracker.get_confirmed_transaction() ==
                   Map.delete(transaction, :originator)
      end

      refute Process.alive?(pid)
    end

    test "logs a message about mismatched hash" do
      transaction = insert(:blockchain_transaction_rootchain)
      {:ok, pid} = BlockchainTransactionTracker.start(transaction, DummyTransactionTracker)

      assert capture_log(fn ->
               :ok = GenServer.cast(pid, {:confirmations_count, "fake", 1})
               _ = Process.sleep(100)
             end) =~ "The receipt has a mismatched hash"

      # A mismatch hash does not stop the tracker so we stop it manually.
      assert GenServer.stop(pid)
    end
  end
end

defmodule EWallet.DummyTransactionTracker do
  @moduledoc """
  Dummy transaction tracker that can be used when testing
  a BlockchainTransactionTracker. This genserver implements
  the `on_confirmed/1` required by the behaviour and set the
  blockchain transaction to its state under the :on_confirmed key.
  """
  use GenServer

  @behaviour EWallet.BlockchainTransactionTrackerBehaviour

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(_opts) do
    {:ok, %{received_confirmed: nil}}
  end

  @impl GenServer
  def handle_cast({:on_confirmed, transaction}, _state) do
    {:noreply, %{received_confirmed: transaction}}
  end

  @impl GenServer
  def handle_call({:get_confirmed_tx}, _from, %{received_confirmed: transaction} = state) do
    {:reply, transaction, state}
  end

  @impl EWallet.BlockchainTransactionTrackerBehaviour
  def on_confirmed(transaction) do
    GenServer.cast(__MODULE__, {:on_confirmed, transaction})
  end

  def get_confirmed_transaction do
    GenServer.call(__MODULE__, {:get_confirmed_tx})
  end
end
