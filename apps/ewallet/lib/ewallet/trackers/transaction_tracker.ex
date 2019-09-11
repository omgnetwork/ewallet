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
  @moduledoc """
  Tracks changes to a blockchain transaction and reflects those changes
  on the respective eWallet transaction.

  This is a GenServer that can be started dynamically for a specific eWallet transaction.
  """
  use GenServer, restart: :temporary
  require Logger

  alias EWallet.{BlockchainHelper, BlockchainTransactionGate}
  alias EWalletDB.{Transaction, TransactionState}
  alias ActivityLogger.System

  @backup_confirmations_threshold 10

  # TODO: handle failed transactions

  def start_link(attrs) do
    GenServer.start_link(__MODULE__, attrs)
  end

  def init(%{transaction: transaction, transaction_type: transaction_type} = attrs) do
    adapter = BlockchainHelper.adapter()
    :ok = adapter.subscribe(:transaction, transaction.blockchain_tx_hash, self())

    {:ok,
     %{
       transaction: transaction,
       # for state changes, see TransactionState.state()'s map keys
       transaction_type: transaction_type,
       # optional
       registry: attrs[:registry]
     }}
  end

  def handle_cast(
        {:confirmations_count, transaction_receipt, confirmations_count},
        %{transaction: transaction} = state
      ) do
    case transaction.blockchain_tx_hash == transaction_receipt.transaction_hash do
      true ->
        adapter = BlockchainHelper.adapter()
        threshold = Application.get_env(:ewallet, :blockchain_confirmations_threshold)

        if is_nil(threshold) do
          Logger.warn("Blockchain Confirmations Threshold not set in configuration: using 10.")
        end

        update_confirmations_count(
          adapter,
          state,
          confirmations_count,
          confirmations_count >= (threshold || @backup_confirmations_threshold)
        )

      false ->
        Logger.error(
          "Unable to update the confirmation count for #{transaction.blockchain_tx_hash}." <>
            " The receipt has a mismatched hash: #{transaction_receipt.transaction_hash}."
        )

        {:noreply, state}
    end
  end

  # Threshold reached, finalizing the transaction...
  defp update_confirmations_count(
         adapter,
         %{transaction: transaction, transaction_type: transaction_type} = state,
         confirmations_count,
         true
       ) do
    # The transaction may have staled as it may took time before this function is invoked.
    # So we'll re-retrieve the transaction from the database before transitioning.
    transaction = Transaction.get(transaction.id)

    {:ok, transaction} =
      TransactionState.transition_to(
        transaction_type,
        TransactionState.blockchain_confirmed(),
        transaction,
        %{
          confirmations_count: confirmations_count,
          originator: %System{}
        }
      )

    # TODO: handle error
    {:ok, transaction} = BlockchainTransactionGate.handle_local_insert(transaction)

    # If to a deposit wallet, make sure it's stored
    _ =
      case BlockchainDepositWallet.get(transaction.to) do
        nil ->
          :noop

        _deposit_wallet ->
          {:ok, _} =
            BlockchainDepositWalletGate.store_balances(
              transaction.to,
              blockchain_identifier,
              [transaction.to_token]
            )
      end

    # Unsubscribing from the blockchain subapp
    # TODO: :ok / {:error, :not_found} handling?
    :ok = adapter.unsubscribe(:transaction, transaction.blockchain_tx_hash, self())

    case is_nil(state[:registry]) do
      true ->
        {:stop, :normal, Map.put(state, :transaction, transaction)}

      false ->
        :ok = GenServer.cast(state[:registry], {:stop_tracker, transaction.uuid})
        {:noreply, Map.put(state, :transaction, transaction)}
    end
  end

  # Treshold not reached yet, updating and continuing to track...
  defp update_confirmations_count(
         _adapter,
         %{transaction: transaction, transaction_type: transaction_type} = state,
         confirmations_count,
         false
       ) do
    # The transaction may have staled as it may took time before this function is invoked.
    # So we'll re-retrieve the transaction from the database before transitioning.
    transaction = Transaction.get(transaction.id)

    {:ok, transaction} =
      TransactionState.transition_to(
        transaction_type,
        TransactionState.pending_confirmations(),
        transaction,
        %{
          confirmations_count: confirmations_count,
          originator: %System{}
        }
      )

    {:noreply, Map.put(state, :transaction, transaction)}
  end
end
