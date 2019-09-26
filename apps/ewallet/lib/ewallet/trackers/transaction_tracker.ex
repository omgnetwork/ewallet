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

  alias EWallet.{
    BlockchainHelper,
    BlockchainTransactionGate
  }

  alias EWalletDB.TransactionState

  @default_confirmations_threshold 10
  @rootchain_identifier BlockchainHelper.rootchain_identifier()

  @registry EWallet.TransactionTrackerRegistry
  @supervisor EWallet.TransactionTrackerSupervisor

  # TODO: handle failed transactions

  @doc """
  Lookup for an already running tracker by its transaction's uuid.
  """
  @spec lookup(String.t(), Registry.registry()) :: {:ok, pid()} | {:error, :not_found}
  def lookup(transaction_uuid, registry \\ @registry) do
    case Registry.lookup(registry, transaction_uuid) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Starts a new supervised TransactionTracker process for the given transaction.
  The tracker is also registered with a registry and so can be looked up
  by its tracking transaction's uuid via the registry.
  """
  def start(transaction, transaction_type, registry \\ @registry) do
    opts = [
      transaction: transaction,
      transaction_type: transaction_type,
      name: {:via, Registry, {registry, transaction.uuid}}
    ]

    DynamicSupervisor.start_child(@supervisor, {__MODULE__, opts})
  end

  @doc """
  Starts the actual TransactionTracker process.
  """
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    state = %{
      transaction: Keyword.fetch!(opts, :transaction),
      transaction_type: Keyword.fetch!(opts, :transaction_type)
    }

    {:ok, state, {:continue, :subscribe_adapter}}
  end

  def handle_continue(:subscribe_adapter, state) do
    :ok =
      BlockchainHelper.adapter().subscribe(
        :transaction,
        state.transaction.blockchain_tx_hash,
        state.transaction.blockchain_identifier != @rootchain_identifier,
        self()
      )

    {:noreply, state}
  end

  def handle_cast({:confirmations_count, tx_hash, confirmations_count, block_num}, state) do
    case state.transaction.blockchain_tx_hash == tx_hash do
      true ->
        # The transaction may have staled as it may took time before this function is invoked.
        # So we'll re-retrieve the transaction from the database before transitioning.
        state = %{state | transaction: refresh_transaction(state.transaction)}

        case confirmations_count >= get_confirmations_threshold() do
          false ->
            transaction = update_confirmations_count(state, confirmations_count, block_num)
            {:noreply, %{state | transaction: transaction}}

          true ->
            transaction = finalize_transaction(state, confirmations_count, block_num)
            {:stop, :normal, %{state | transaction: transaction}}
        end

      false ->
        _ =
          Logger.error(
            "Unable to handle the confirmations count for #{state.transaction.blockchain_tx_hash}." <>
              " The receipt has a mismatched hash: #{tx_hash}."
          )

        {:noreply, state}
    end
  end

  # TODO: handle_cast for failures

  # Handle transactions that are not yet included in a block / or invalid tx_hash
  def handle_cast({:not_found}, state) do
    # TODO: Implement threshold to stop tracking an invalid transactioon
    # If the transaction remains not_found for xxxx blocks, unsubscribe.
    {:noreply, state}
  end

  defp refresh_transaction(%schema{} = transaction) do
    schema.get(transaction.id)
  end

  defp get_confirmations_threshold do
    case Application.get_env(:ewallet, :blockchain_confirmations_threshold) do
      nil ->
        _ = Logger.warn("Blockchain Confirmations Threshold not set in configuration: using 10.")
        @default_confirmations_threshold

      threshold ->
        threshold
    end
  end

  #
  # Functions for ongoing transaction
  #

  defp update_confirmations_count(state, confirmations_count, block_num) do
    {:ok, transaction} =
      TransactionState.transition_to(
        state.transaction_type,
        TransactionState.pending_confirmations(),
        state.transaction,
        %{
          blk_number: block_num,
          confirmations_count: confirmations_count,
          originator: %System{}
        }
      )

    transaction
  end

  #
  # Functions for finalizing a transaction
  #

  defp finalize_transaction(state, confirmations_count, block_num) do
    with {:ok, updated} <-
           confirm(state.transaction, state.transaction_type, confirmations_count, block_num) |> IO.inspect(label: "before local insert"),
         {:ok, updated} <- BlockchainTransactionGate.handle_local_insert(updated) do
      updated
    else
      {:error, _} = error ->
        _ =
          Logger.error(fn ->
            "The transaction did not finalize completely after" <>
              " the confirmations count have reached threshold. Got: #{inspect(error)}."
          end)

        state.transaction
    end
  end

  defp confirm(transaction, transaction_type, confirmations_count, block_num) do
    TransactionState.transition_to(
      transaction_type,
      TransactionState.blockchain_confirmed(),
      transaction,
      %{
        blk_number: block_num,
        confirmations_count: confirmations_count,
        originator: %System{}
      }
    )
  end
end
