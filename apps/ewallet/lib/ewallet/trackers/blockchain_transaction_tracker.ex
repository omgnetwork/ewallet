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

defmodule EWallet.BlockchainTransactionTracker do
  @moduledoc """
  Tracks changes to a blockchain transaction and reflects those changes
  on the respective eWallet transaction.

  This is a GenServer that can be started dynamically for a specific blockchain transaction.
  """
  use GenServer, restart: :temporary
  require Logger
  alias ActivityLogger.System

  alias EWallet.{
    BlockchainHelper,
    BlockchainStateGate
  }

  alias EWalletDB.{BlockchainTransaction, BlockchainTransactionState}

  @default_confirmations_threshold 10
  @rootchain_identifier BlockchainHelper.rootchain_identifier()

  @registry EWallet.TransactionTrackerRegistry
  @supervisor EWallet.TransactionTrackerSupervisor

  # TODO: handle failed transactions

  @doc """
  Lookup for an already running tracker by its blockchain_transaction's uuid.
  """
  @spec lookup(String.t(), Registry.registry()) :: {:ok, pid()} | {:error, :not_found}
  def lookup(blockchain_transaction_uuid, registry \\ @registry) do
    case Registry.lookup(registry, blockchain_transaction_uuid) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Starts a new supervised BlockchainTransactionTracker process for the given transaction.
  The tracker is also registered with a registry and so can be looked up
  by its tracking blockchain transaction's uuid via the registry.
  """
  def start(blockchain_transaction, callback_module, registry \\ @registry) do
    opts = [
      callback_module: callback_module,
      blockchain_transaction: blockchain_transaction,
      name: {:via, Registry, {registry, blockchain_transaction.uuid}}
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
      callback_module: Keyword.fetch!(opts, :callback_module),
      blockchain_transaction: Keyword.fetch!(opts, :blockchain_transaction)
    }

    {:ok, state, {:continue, :subscribe_adapter}}
  end

  def handle_continue(
        :subscribe_adapter,
        %{blockchain_transaction: %{hash: hash, childchain_identifier: childchain_identifier}} =
          state
      ) do
    :ok =
      BlockchainHelper.adapter().subscribe(
        :transaction,
        hash,
        childchain_identifier != nil,
        self()
      )

    {:noreply, state}
  end

  def handle_cast(
        {:confirmations_count, hash, block_number},
        %{blockchain_transaction: blockchain_transaction} = state
      ) do
    case blockchain_transaction.hash == hash do
      true ->
        # The transaction may have staled as it may took time before this function is invoked.
        # So we'll re-retrieve the transaction from the database before transitioning.
        state = %{state | blockchain_transaction: refresh_transaction(blockchain_transaction)}
        eth_height = BlockchainStateGate.get_last_synced_blk_number(@rootchain_identifier)
        confirmations_count = eth_height - block_number + 1

        case confirmations_count >= get_confirmations_threshold() do
          false ->
            blockchain_transaction = update_confirmations_count(state, block_number)
            {:noreply, %{state | blockchain_transaction: blockchain_transaction}}

          true ->
            blockchain_transaction = finalize_transaction(state, eth_height, block_number)
            {:stop, :normal, %{state | blockchain_transaction: blockchain_transaction}}
        end

      false ->
        _ =
          Logger.error(
            "Unable to handle the confirmations count for #{blockchain_transaction.hash}." <>
              " The receipt has a mismatched hash: #{hash}."
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

  defp refresh_transaction(blockchain_transaction) do
    BlockchainTransaction.get_by(uuid: blockchain_transaction.uuid)
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

  defp update_confirmations_count(state, block_number) do
    {:ok, transaction} =
      BlockchainTransactionState.transition_to(
        BlockchainTransactionState.pending_confirmations(),
        state.blockchain_transaction,
        %{
          block_number: block_number,
          originator: %System{}
        }
      )

    transaction
  end

  #
  # Functions for finalizing a transaction
  #

  defp finalize_transaction(
         %{blockchain_transaction: blockchain_transaction, callback_module: callback_module},
         eth_height,
         block_number
       ) do
    with {:ok, updated} <-
           confirm(blockchain_transaction, eth_height, block_number) do
      callback_module.on_confirmed(updated)
      updated
    else
      {:error, _} = error ->
        _ =
          Logger.error(fn ->
            "The transaction did not finalize completely after" <>
              " the confirmations count have reached threshold. Got: #{inspect(error)}."
          end)

        blockchain_transaction
    end
  end

  defp confirm(blockchain_transaction, eth_height, block_number) do
    BlockchainTransactionState.transition_to(
      BlockchainTransactionState.confirmed(),
      blockchain_transaction,
      %{
        block_number: block_number,
        confirmed_at_block_number: eth_height,
        originator: %System{}
      }
    )
  end
end
