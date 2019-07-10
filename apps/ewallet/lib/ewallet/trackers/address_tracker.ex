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

  # TODO: Have two different intervals: one for syncing and one for day-to-day block retrieval (slower)

  alias EWallet.BlockchainHelper
  alias EWalletDB.{BlockchainWallet, Token, Transaction}
  alias ActivityLogger.System

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    attrs = Keyword.get(opts, :attrs, %{})
    GenServer.start_link(__MODULE__, attrs, name: name)
  end

  def init(%{interval: interval, blockchain: blockchain}) do
    wallet = BlockchainWallet.get_by(type: "hot")
    addresses = [wallet.address]
    tokens = Token.all_blockchain()
    contract_addresses = Enum.map(tokens, fn token -> token.blockchain_address end)
    blk_number = Transaction.get_last_blk_number(blockchain)
    IO.inspect("Starting at block number #{blk_number}")

    {:ok, %{
      interval: interval,
      blockchain: blockchain,
      timer: nil,
      addresses: addresses,
      contract_addresses: contract_addresses,
      tokens: tokens,
      blk_number: blk_number,
      blk_retries: 0
    }, {:continue, :start_polling}}
  end

  def handle_continue(:start_polling, state) do
    poll(state)
  end

  def handle_info(:poll,state) do
    poll(state)
  end

  defp poll( %{interval: interval} = state) do
    IO.inspect("Ticking!")
    new_state = run(state)
    timer = Process.send_after(self(), :poll, interval)
    {:noreply, %{new_state | timer: timer}}
  end

  def measure(function, name) do
    {time, value} = :timer.tc(function)
    Logger.info("#{name} #{:erlang.float_to_binary(time / 1_000_000, [decimals: 10])}s")
    value
  end

  defp run(
         %{
           blk_number: blk_number,
           addresses: addresses,
           contract_addresses: contract_addresses
         } = state
       ) do
    IO.inspect("Running for block: #{blk_number}")

    transaction_results = measure(fn ->
      BlockchainHelper.call(:get_transactions, %{
        blk_number: blk_number,
        addresses: addresses,
        contract_addresses: contract_addresses
      })
    end, "get_transactions")

    transaction_results =
      transaction_results
      |> Enum.map(fn tx ->
        insert(tx, state)
      end)
    case Enum.all?(transaction_results, fn res -> res == :ok end) do
      true ->
        next(state)

      false ->
        retry_or_skip(state, transaction_results)
    end
  end

  defp next(%{blk_number: blk_number} = state) do
    state
    |> Map.put(:blk_number, blk_number + 1)
    |> Map.put(:blk_retries, 0)
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

  defp do_insert(blockchain_tx, %{blockchain: blockchain}) do
    token = Token.get_by(%{blockchain_address: blockchain_tx.contract_address})
    IO.inspect("Inserting new transaction...")
    attrs = %{
      idempotency_token: blockchain_tx.hash,
      from_amount: blockchain_tx.amount,
      to_amount: blockchain_tx.amount,
      status: get_status(blockchain_tx.confirmations_count),
      type: Transaction.external(),
      blockchain_tx_hash: blockchain_tx.hash,
      blockchain_identifier: blockchain,
      confirmations_count: blockchain_tx.confirmations_count,
      blk_number: blockchain_tx.block_number,
      payload: blockchain_tx.original,
      blockchain_metadata: %{},#%{data: blockchain_tx.data}, # TODO: encode this in a save-able way
      from_token_uuid: token.uuid,
      to_token_uuid: token.uuid,
      to_wallet: nil,
      from_wallet: nil,
      from_blockchain_address: blockchain_tx.from,
      to_blockchain_address: blockchain_tx.to,
      from_account: nil,
      to_account: nil,
      from_user: nil,
      to_user: nil,
      originator: %System{} # TODO: Change this to a new originator
    }

    # TODO: Notify websockets
    # TODO: Add value in local ledger if needed
    # TODO: need to check if funds need to be added to an internal wallet
    # TODO: Setup transaction tracker if pending confirmations
    case Transaction.insert(attrs) do
      {:ok, _} ->
        :ok

      error ->
        error
    end
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
end
