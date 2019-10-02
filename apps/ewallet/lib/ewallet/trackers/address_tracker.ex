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

defmodule EWallet.AddressTracker do
  @moduledoc """
  This module is a GenServer started dynamically for a specific eWallet transaction
  It will registers itself with the blockchain adapter to receive events about
  a given transactions and act on it
  """
  use GenServer
  require Logger

  alias EWallet.{
    BlockchainHelper,
    BlockchainAddressFetcher,
    BlockchainStateGate,
    TransactionGate
  }

  alias EWalletDB.{
    BlockchainState,
    BlockchainTransactionState,
    Token,
    Transaction,
    TransactionState
  }

  alias ActivityLogger.System

  # TODO: only starts when blockchain is enabled

  # TODO: make these numbers admin-configurable
  @blk_syncing_save_interval 5
  @blk_syncing_polling_interval 5
  @syncing_interval 50
  # 15000
  @polling_interval 500

  @spec start_link(keyword) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    attrs = Keyword.get(opts, :attrs, %{})
    GenServer.start_link(__MODULE__, attrs, name: name)
  end

  def init(%{blockchain_identifier: blockchain_identifier} = attrs) do
    {:ok,
     %{
       interval: @syncing_interval,
       blockchain_identifier: blockchain_identifier,
       timer: nil,
       addresses:
         BlockchainAddressFetcher.get_all_trackable_wallet_addresses(blockchain_identifier),
       contract_addresses:
         BlockchainAddressFetcher.get_all_trackable_contract_address(blockchain_identifier),
       blk_number: BlockchainStateGate.get_last_synced_blk_number(blockchain_identifier),
       blk_retries: 0,
       blk_syncing_save_count: 0,
       blk_syncing_save_interval: @blk_syncing_save_interval,
       node_adapter: attrs[:node_adapter],
       stop_once_synced: attrs[:stop_once_synced] || false
     }, {:continue, :start_polling}}
  end

  def handle_continue(:start_polling, state) do
    poll(state)
  end

  def handle_info(:poll, state) do
    poll(state)
  end

  def handle_call(
        {:register_address, blockchain_address, internal_address},
        _from,
        %{addresses: addresses} = state
      ) do
    case addresses[blockchain_address] do
      nil ->
        addresses = Map.put(addresses, blockchain_address, internal_address)
        {:reply, :ok, %{state | addresses: addresses}}

      _ ->
        {:reply, :ok, state}
    end
  end

  def register_address(blockchain_address, internal_address, pid \\ __MODULE__) do
    GenServer.call(pid, {:register_address, blockchain_address, internal_address})
  end

  defp poll(state) do
    case run(state) do
      new_state when is_map(new_state) ->
        timer = Process.send_after(self(), :poll, new_state[:interval])
        {:noreply, %{new_state | timer: timer}}

      error ->
        error
    end
  end

  defp run(
         %{
           blk_number: blk_number,
           addresses: addresses,
           contract_addresses: contract_addresses,
           node_adapter: node_adapter,
           stop_once_synced: stop_once_synced
         } = state
       ) do
    attrs = %{
      blk_number: blk_number,
      addresses: Map.keys(addresses),
      contract_addresses: contract_addresses
    }

    case BlockchainHelper.call(:get_transactions, attrs, eth_node_adapter: node_adapter) do
      {:error, :block_not_found} ->
        case stop_once_synced do
          false ->
            # We've reached the end of the chain, switching to a slower polling interval
            # TODO: Make this less spammy
            # Logger.info("Block #{blk_number} not found, retrying in #{@polling_interval}ms...")

            state
            |> Map.put(:interval, @polling_interval)
            |> Map.put(:blk_syncing_save_interval, @blk_syncing_polling_interval)

          true ->
            {:stop, :normal, state}
        end

      {:error, _} = error ->
        Logger.error("No blockchain handler found, terminating...")
        {:stop, error, state}

      transactions ->
        do_run(transactions, state)
    end
  end

  defp do_run(transactions, state) do
    transaction_results = Enum.map(transactions, fn tx -> insert(tx, state) end)

    case Enum.all?(transaction_results, fn {res, _} -> res == :ok end) do
      true ->
        next(state)

      false ->
        retry_or_skip(state, transaction_results)
    end
  end

  defp next(%{blk_number: blk_number, blockchain_identifier: blockchain_identifier} = state) do
    new_blk_number = blk_number + 1

    case state[:blk_syncing_save_count] < state[:blk_syncing_save_interval] do
      true ->
        state
        |> Map.put(:blk_syncing_save_count, state[:blk_syncing_save_count] + 1)
        |> Map.put(:blk_number, new_blk_number)
        |> Map.put(:blk_retries, 0)

      false ->
        {:ok, blockchain_state} = BlockchainState.update(blockchain_identifier, new_blk_number)

        state
        |> Map.put(:blk_syncing_save_count, 0)
        |> Map.put(:blk_number, blockchain_state.blk_number)
        |> Map.put(:blk_retries, 0)
    end
  end

  defp retry_or_skip(%{blk_number: blk_number, blk_retries: retries} = state, transaction_results)
       when retries > 2 do
    errors =
      Enum.reduce(transaction_results, [], fn res, acc ->
        case res do
          {:ok, _} ->
            acc

          error ->
            [error | acc]
        end
      end)

    Logger.error(
      "Failed to insert transactions for block #{blk_number} #{retries} times. Skipping...",
      errors
    )

    next(state)
  end

  defp retry_or_skip(%{blk_number: blk_number, blk_retries: retries} = state, _) do
    Logger.warn(
      "Failed to insert transactions for block #{blk_number}. Retrying: #{retries + 1}/3"
    )

    Map.put(state, :blk_retries, retries + 1)
  end

  defp insert(blockchain_transaction, %{blockchain_identifier: blockchain_identifier} = state) do
    case Transaction.get_by(%{
           blockchain_tx_hash: blockchain_transaction.hash,
           blockchain_identifier: blockchain_identifier
         }) do
      nil ->
        do_insert(blockchain_transaction, state)

      transaction ->
        {:ok, transaction}
    end
  end

  defp do_insert(blockchain_tx, %{
         addresses: addresses,
         blockchain_identifier: blockchain_identifier
       }) do
    token = Token.get_by(%{blockchain_address: blockchain_tx.contract_address})
    # TODO: Notify websockets
    blockchain_transaction_attrs = %{
      hash: blockchain_tx.hash,
      rootchain_identifier: blockchain_identifier,
      childchain_identifier: nil,
      status: BlockchainTransactionState.submitted(),
      block_number: blockchain_tx.block_number
    }

    transaction_attrs = %{
      idempotency_token: blockchain_tx.hash,
      from_amount: blockchain_tx.amount,
      to_amount: blockchain_tx.amount,
      status: TransactionState.pending(),
      type: Transaction.external(),
      payload: %{},
      # %{data: blockchain_tx.data}, # TODO: encode this in a save-able way
      from_token_uuid: token.uuid,
      to_token_uuid: token.uuid,
      to: addresses[blockchain_tx.to],
      from: nil,
      from_blockchain_address: blockchain_tx.from,
      to_blockchain_address: blockchain_tx.to,
      from_account: nil,
      to_account: nil,
      from_user: nil,
      to_user: nil,
      # TODO: Change this to a new originator "%Tracker{}"?
      originator: %System{}
    }

    TransactionGate.Blockchain.create_from_tracker(
      blockchain_transaction_attrs,
      transaction_attrs
    )
  end
end
