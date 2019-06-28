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

defmodule EWallet.TransactionTracker do
  use GenServer, restart: :temporary
  require Logger

  alias EWallet.BlockchainTransactionState
  alias ActivityLogger.System

  # TODO: handle failed transactions

  def start_link(transaction) do
    GenServer.start_link(__MODULE__, transaction)
  end

  def init(transaction) do
    adapter = Application.get_env(:ewallet, :blockchain_adapter)
    :ok = adapter.subscribe(:transaction, transaction.blockchain_tx_hash, self())
    {:ok, transaction}
  end

  def handle_cast({:confirmations_count, tx_hash, confirmations_count}, transaction) do
    case transaction.blockchain_tx_hash == tx_hash do
      true ->
        adapter = Application.get_env(:ewallet, :blockchain_adapter)
        threshold = Application.get_env(:ewallet, :blockchain_confirmations_threshold)

        if is_nil(threshold) do
          Logger.warn("Blockchain Confirmations Threshold not set in configuration: using 10.")
        end

        update_confirmations_count(
          adapter,
          transaction,
          confirmations_count,
          confirmations_count > (threshold || 10)
        )

      false ->
        {:noreply, transaction}
    end
  end

  # Treshold reached, finalizing the transaction...
  defp update_confirmations_count(adapter, transaction, confirmations_count, true) do
    {:ok, transaction} =
      BlockchainTransactionState.transition_to(
        :confirmed,
        transaction,
        confirmations_count,
        %System{}
      )

    # Unsubscribing from the blockchain subapp
    :ok = adapter.unsubscribe(:transaction, transaction.blockchain_tx_hash, self())

    # Kill thyself
    {:stop, :normal, transaction}
  end

  # Treshold not reached yet, updating and continuing to track...
  defp update_confirmations_count(_adapter, transaction, confirmations_count, false) do
    {:ok, transaction} =
      BlockchainTransactionState.transition_to(
        :pending_confirmations,
        transaction,
        confirmations_count,
        %System{}
      )

    {:noreply, transaction}
  end
end
