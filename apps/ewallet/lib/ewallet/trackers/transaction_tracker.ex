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
  alias ActivityLogger.System
  alias EWallet.{BlockchainDepositWalletGate, BlockchainHelper, BlockchainTransactionGate}
  alias EWallet.Web.Preloader
  alias EWalletDB.{BlockchainDepositWallet, TransactionState}

  @backup_confirmations_threshold 10

  @rootchain_identifier BlockchainHelper.rootchain_identifier()

  # TODO: handle failed transactions

  def start_link(attrs) do
    GenServer.start_link(__MODULE__, attrs)
  end

  def init(%{transaction: transaction, transaction_type: transaction_type} = attrs) do
    adapter = BlockchainHelper.adapter()

    :ok =
      adapter.subscribe(
        :transaction,
        transaction.blockchain_tx_hash,
        transaction.blockchain_identifier != @rootchain_identifier,
        self()
      )

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
        {:confirmations_count, transaction_hash, confirmations_count, block_number},
        %{transaction: transaction} = state
      ) do
    case transaction.blockchain_tx_hash == transaction_hash do
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
          block_number,
          confirmations_count >= (threshold || @backup_confirmations_threshold)
        )

      false ->
        Logger.error(
          "Unable to update the confirmation count for #{transaction.blockchain_tx_hash}." <>
            " The receipt has a mismatched hash: #{transaction_hash}."
        )

        {:noreply, state}
    end
  end

  # Transaction not yet included in a block / or invalid tx_hash
  def handle_cast({:not_found}, state) do
    # TODO Implement threshold to stop tracking an invalid transactioon
    # If the transaction remains not_found for xxxx blocks, unsubscribe.
    {:noreply, state}
  end

  # TODO handle_cast for failures

  # Threshold reached, finalizing the transaction...
  defp update_confirmations_count(
         adapter,
         %{transaction: %schema{} = transaction, transaction_type: transaction_type} = state,
         confirmations_count,
         _block_number,
         true
       ) do
    # The transaction may have staled as it may took time before this function is invoked.
    # So we'll re-retrieve the transaction from the database before transitioning.
    transaction = schema.get(transaction.id)

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

    # If the transaction is to a deposit wallet, make sure the deposit wallet's
    # local copy of its blockchain balances is refreshed.
    _ =
      case BlockchainDepositWallet.get(transaction.to_blockchain_address) do
        nil ->
          :noop

        _deposit_wallet ->
          {:ok, transaction} = Preloader.preload_one(transaction, :to_token)

          {:ok, _} =
            BlockchainDepositWalletGate.refresh_balances(
              transaction.to_blockchain_address,
              transaction.blockchain_identifier,
              transaction.to_token
            )
      end

    #
    # The transaction is now confirmed. Stop the tracker.
    #

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

  # Threshold not reached yet, updating and continuing to track...
  defp update_confirmations_count(
         _adapter,
         %{transaction: %schema{} = transaction, transaction_type: transaction_type} = state,
         confirmations_count,
         block_number,
         false
       ) do
    # The transaction may have staled as it may took time before this function is invoked.
    # So we'll re-retrieve the transaction from the database before transitioning.
    transaction = schema.get(transaction.id)

    {:ok, transaction} =
      TransactionState.transition_to(
        transaction_type,
        TransactionState.pending_confirmations(),
        transaction,
        %{
          blk_number: block_number,
          confirmations_count: confirmations_count,
          originator: %System{}
        }
      )

    {:noreply, Map.put(state, :transaction, transaction)}
  end
end
