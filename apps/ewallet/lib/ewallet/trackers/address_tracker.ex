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
  use GenServer, restart: :temporary
  require Logger

  alias EWallet.BlockchainHelper
  alias EWalletDB.{BlockchainWallet, BlockchainDepositWallet, BlockchainState, Token, Transaction}
  alias ActivityLogger.System

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

  def init(%{blockchain: blockchain}) do
    wallet = BlockchainWallet.get_by(type: "hot")
    addresses = %{wallet.address => nil}
    tokens = Token.all_blockchain(blockchain)
    contract_addresses = Enum.map(tokens, fn token -> token.blockchain_address end)
    tx_blk_number = Transaction.get_last_blk_number(blockchain)
    global_blk_number = get_global_blk_number(blockchain)
    blk_number = get_starting_blk_number(blockchain, global_blk_number, tx_blk_number)

    # TODO: Load all addresses from blockchain deposit wallets
    addresses =
      BlockchainDepositWallet.all()
      |> Enum.map(fn deposit_wallet -> {deposit_wallet.address, deposit_wallet.wallet_address} end)
      |> Enum.into(%{})
      |> Map.merge(addresses)

    IO.inspect("Starting at block number #{blk_number}")

    {:ok,
     %{
       interval: @syncing_interval,
       blockchain: blockchain,
       timer: nil,
       addresses: addresses,
       contract_addresses: contract_addresses,
       tokens: tokens,
       blk_number: blk_number,
       blk_retries: 0,
       blk_syncing_save_count: 0,
       blk_syncing_save_interval: @blk_syncing_save_interval
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
        %{addresses: addresses} = state
      ) do
    case addresses[blockchain_address] do
      nil ->
        {:ok, :ok, state}

      _ ->
        addresses = Map.put(addresses, blockchain_address, internal_address)
        {:ok, :ok, %{state | addresses: addresses}}
    end
  end

  def register_address(blockchain_address, internal_address, pid \\ __MODULE__) do
    GenServer.call(pid, {:register_address, blockchain_address, internal_address})
  end

  defp poll(state) do
    new_state = run(state)
    timer = Process.send_after(self(), :poll, new_state[:interval])
    {:noreply, %{new_state | timer: timer}}
  end

  defp run(
         %{
           blk_number: blk_number,
           addresses: addresses,
           contract_addresses: contract_addresses
         } = state
       ) do
    # IO.inspect("Syncing with block #{blk_number}...")

    attrs = %{
      blk_number: blk_number,
      addresses: Map.keys(addresses),
      contract_addresses: contract_addresses
    }

    case BlockchainHelper.call(:get_transactions, attrs) do
      {:error, :block_not_found} ->
        # We've reached the end of the chain, switching to a slower polling interval
        # Logger.info("Block #{blk_number} not found, retrying in #{@polling_interval}ms...")
        state
        |> Map.put(:interval, @polling_interval)
        |> Map.put(:blk_syncing_save_interval, @blk_syncing_polling_interval)

      transactions ->
        transaction_results = Enum.map(transactions, fn tx -> insert(tx, state) end)

        case Enum.all?(transaction_results, fn res -> res == :ok end) do
          true ->
            next(state)

          false ->
            retry_or_skip(state, transaction_results)
        end
    end
  end

  defp next(%{blk_number: blk_number, blockchain: blockchain} = state) do
    new_blk_number = blk_number + 1

    case state[:blk_syncing_save_count] < state[:blk_syncing_save_interval] do
      true ->
        state
        |> Map.put(:blk_syncing_save_count, state[:blk_syncing_save_count] + 1)
        |> Map.put(:blk_number, new_blk_number)
        |> Map.put(:blk_retries, 0)

      false ->
        {:ok, blockchain_state} = BlockchainState.update(blockchain, new_blk_number)

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
        case res == :ok do
          false ->
            [res | acc]

          true ->
            acc
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

  defp insert(blockchain_transaction, %{blockchain: blockchain} = state) do
    case Transaction.get_by(%{
           blockchain_tx_hash: blockchain_transaction.hash,
           blockchain_identifier: blockchain
         }) do
      nil ->
        do_insert(blockchain_transaction, state)

      _transaction ->
        :ok
    end
  end

  defp do_insert(blockchain_tx, %{addresses: addresses, blockchain: blockchain}) do
    token = Token.get_by(%{blockchain_address: blockchain_tx.contract_address})

    attrs = %{
      idempotency_token: blockchain_tx.hash,
      from_amount: blockchain_tx.amount,
      to_amount: blockchain_tx.amount,
      # get_status(blockchain_tx.confirmations_count),
      status: Transaction.pending_recording(),
      type: Transaction.external(),
      blockchain_tx_hash: blockchain_tx.hash,
      blockchain_identifier: blockchain,
      confirmations_count: blockchain_tx.confirmations_count,
      blk_number: blockchain_tx.block_number,
      payload: blockchain_tx.original,
      # %{data: blockchain_tx.data}, # TODO: encode this in a save-able way
      blockchain_metadata: %{},
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
      # TODO: Change this to a new originator "%Tracker{}"
      originator: %System{}
    }

    {:ok, _} = EWallet.BlockchainTransactionGate.create_from_tracker(attrs)

    :ok

    # TODO: Notify websockets
    # TODO: Add value in local ledger if needed
    # TODO: need to check if funds need to be added to an internal wallet
    # TODO: Setup transaction tracker if pending confirmations
    # case Transaction.insert(attrs) do
    #   {:ok, _} ->
    #     :ok

    #   error ->
    #     error
    # end
  end

  defp get_status(confirmations_count) do
    threshold = Application.get_env(:ewallet, :blockchain_confirmations_threshold)

    if is_nil(threshold) do
      Logger.warn("Blockchain Confirmations Threshold not set in configuration: using 10.")
    end

    case confirmations_count > (threshold || 10) do
      true ->
        Transaction.confirmed()

      false ->
        Transaction.pending_confirmations()
    end
  end

  defp get_global_blk_number(blockchain) do
    case BlockchainState.get(blockchain) do
      nil ->
        {:ok, state} = BlockchainState.insert(%{identifier: blockchain})
        state.blk_number

      state ->
        state.blk_number
    end
  end

  defp get_starting_blk_number(_blockchain, global_blk_number, nil), do: global_blk_number

  defp get_starting_blk_number(blockchain, global_blk_number, tx_blk_number)
       when is_integer(global_blk_number) and is_integer(tx_blk_number) do
    case global_blk_number > tx_blk_number do
      true ->
        global_blk_number

      false ->
        # update global blk number
        {:ok, state} = BlockchainState.update(blockchain, tx_blk_number)
        state.blk_number
    end
  end
end
