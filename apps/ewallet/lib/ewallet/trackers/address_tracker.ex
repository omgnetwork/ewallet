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
  use GenServer, restart: :transient
  require Logger

  alias EWallet.{
    BlockchainHelper,
    BlockchainAddressFetcher,
    BlockchainStateGate,
    DepositPoolingGate,
    TransactionGate
  }

  alias EWalletDB.{
    BlockchainState,
    BlockchainTransaction,
    BlockchainTransactionState,
    Token,
    Transaction,
    TransactionState
  }

  alias ActivityLogger.System

  @default_sync_interval 1000
  @default_poll_interval 1000
  @default_state_save_interval 5

  #
  # GenServer lifecycle
  #

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec stop(GenServer.server()) :: :ok
  def stop(pid \\ __MODULE__) do
    GenServer.stop(pid, :normal)
  end

  #
  # Client APIs
  #

  @spec register_address(String.t(), String.t(), GenServer.server()) :: :ok
  def register_address(blockchain_address, internal_address, pid \\ __MODULE__) do
    GenServer.call(pid, {:register_address, blockchain_address, internal_address})
  end

  @spec register_contract_address(String.t(), GenServer.server()) :: :ok
  def register_contract_address(contract_address, pid \\ __MODULE__) do
    GenServer.call(pid, {:register_contract_address, contract_address})
  end

  @spec set_interval(:sync | :poll | :state_save, non_neg_integer(), GenServer.server()) :: :ok
  def set_interval(sync_mode, interval, pid \\ __MODULE__) do
    GenServer.cast(pid, {:set_interval, sync_mode, interval})
  end

  #
  # GenServer callbacks
  #

  def init(opts) do
    # Notice we're not using Application.get_env/3 here for defaults? It's because we populate
    # this config from the database, which may return nil. This function then treats the nil
    # as an existing value, and so get_env/3 would never pick up the local defaults here.
    case Application.get_env(:ewallet, :blockchain_enabled, true) do
      true ->
        blockchain_identifier = Keyword.fetch!(opts, :blockchain_identifier)

        state = %{
          sync_mode: :sync,
          sync_interval:
            Application.get_env(:ewallet, :blockchain_sync_interval) || @default_sync_interval,
          poll_interval:
            Application.get_env(:ewallet, :blockchain_poll_interval) || @default_poll_interval,
          blockchain_identifier: blockchain_identifier,
          timer: nil,
          addresses:
            BlockchainAddressFetcher.get_all_trackable_wallet_addresses(blockchain_identifier),
          contract_addresses:
            BlockchainAddressFetcher.get_all_trackable_contract_address(blockchain_identifier),
          blk_number: BlockchainStateGate.get_last_synced_blk_number(blockchain_identifier),
          blk_retries: 0,
          blk_syncing_save_count: 0,
          blockchain_state_save_interval:
            Application.get_env(:ewallet, :blockchain_state_save_interval) ||
              @default_state_save_interval,
          node_adapter: opts[:node_adapter],
          stop_once_synced: opts[:stop_once_synced] || false
        }

        {:ok, state, {:continue, :start_polling}}

      false ->
        _ = Logger.info("AddressTracker did not start. Blockchain is not enabled.")
        :ignore
    end
  end

  def handle_continue(:start_polling, state) do
    _ = Logger.info("AddressTracker started and is now polling.")
    poll(state)
  end

  def handle_info(:poll, state) do
    poll(state)
  end

  def handle_call({:register_address, blockchain_address, internal_address}, _from, state) do
    case state.addresses[blockchain_address] do
      nil ->
        addresses = Map.put(state.addresses, blockchain_address, internal_address)
        {:reply, :ok, %{state | addresses: addresses}}

      _ ->
        {:reply, :ok, state}
    end
  end

  def handle_call({:register_contract_address, contract_address}, _from, state) do
    {:reply, :ok, %{state | contract_addresses: [contract_address | state.contract_addresses]}}
  end

  def handle_cast({:set_interval, mode, interval}, state) do
    state =
      case mode do
        :sync -> %{state | sync_interval: interval}
        :poll -> %{state | poll_interval: interval}
        :state_save -> %{state | blockchain_state_save_interval: interval}
      end

    case {state.sync_mode, state.timer} do
      # If the updated interval is for the current sync mode and there's no timer set
      # (possibly because the interval was set to 0 before), schedule next poll right away.
      {^mode, nil} ->
        timer = schedule_next_poll(state)
        {:noreply, %{state | timer: timer}}

      # If the updated interval is for the current sync mode and there's a timer set,
      # cancel the current timer and schedule the next poll.
      {^mode, timer} ->
        _ = Process.cancel_timer(timer)
        timer = schedule_next_poll(state)
        {:noreply, %{state | timer: timer}}

      # If the updated interval is for a different sync mode, do nothing and return the
      # timer unchanged.
      _ ->
        {:noreply, state}
    end
  end

  #
  # Polling management
  #

  defp poll(state) do
    case track_addresses(state) do
      new_state when is_map(new_state) ->
        timer = schedule_next_poll(new_state)
        {:noreply, %{new_state | timer: timer}}

      {:error, :block_not_found} ->
        case state.stop_once_synced do
          true ->
            {:stop, :normal, state}

          false ->
            # We've reached the end of the chain, switching to a slower polling interval.
            new_state = %{state | sync_mode: :poll}
            timer = schedule_next_poll(new_state)
            {:noreply, %{state | timer: timer}}
        end

      {:error, error} ->
        _ = Logger.error("An unexpected error occured in the AddressTracker. Terminating...")
        {:stop, error, state}
    end
  end

  defp schedule_next_poll(state) do
    case get_interval(state) do
      interval when interval > 0 ->
        Process.send_after(self(), :poll, interval)

      interval ->
        _ = Logger.info("Address tracking has paused because the interval is #{interval}.")
        nil
    end
  end

  defp get_interval(state) do
    case state.sync_mode do
      :sync -> state.sync_interval
      :poll -> state.poll_interval
    end
  end

  #
  # Address tracking
  #

  defp track_addresses(
         %{
           blk_number: blk_number,
           addresses: addresses,
           contract_addresses: contract_addresses,
           node_adapter: node_adapter
         } = state
       ) do
    attrs = %{
      blk_number: blk_number,
      addresses: Map.keys(addresses),
      contract_addresses: contract_addresses
    }

    case BlockchainHelper.call(:get_transactions, attrs, eth_node_adapter: node_adapter) do
      {:error, _} = error ->
        error

      transactions ->
        do_track_addresses(transactions, state)
    end
  end

  defp do_track_addresses(transactions, state) do
    transaction_results = Enum.map(transactions, fn t -> insert_if_new(t, state) end)

    _ =
      Enum.each(transaction_results, fn
        {:ok, t} ->
          _ = Task.start(fn -> DepositPoolingGate.on_blockchain_transaction_received(t) end)

        _ ->
          :noop
      end)

    transaction_results
    |> Enum.all?(fn {res, _} -> res == :ok end)
    |> case do
      true -> next(state)
      false -> retry_or_skip(state, transaction_results)
    end
  end

  defp next(%{blk_number: blk_number, blockchain_identifier: blockchain_identifier} = state) do
    new_blk_number = blk_number + 1

    case state[:blk_syncing_save_count] < state[:blockchain_state_save_interval] do
      true ->
        state
        |> Map.put(:blk_syncing_save_count, state[:blk_syncing_save_count] + 1)
        |> Map.put(:blk_number, new_blk_number)
        |> Map.put(:blk_retries, 0)

      false ->
        {:ok, blockchain_state} = BlockchainState.update(blockchain_identifier, new_blk_number)

        # Because the save count and checking happens at the end, it starts at 1.
        state
        |> Map.put(:blk_syncing_save_count, 1)
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

  defp insert_if_new(
         blockchain_transaction,
         %{blockchain_identifier: blockchain_identifier} = state
       ) do
    case BlockchainTransaction.get_by(%{
           hash: blockchain_transaction.hash,
           rootchain_identifier: blockchain_identifier
         }) do
      nil ->
        do_insert(blockchain_transaction, state)

      transaction ->
        {:ok, Transaction.get_by(blockchain_transaction_uuid: transaction.uuid)}
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
      status: BlockchainTransactionState.pending_confirmations(),
      block_number: blockchain_tx.block_number,
      originator: %System{}
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
