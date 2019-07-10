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

  alias EWallet.{BlockchainHelper, BlockchainTransactionState}
  alias EWalletDB.{BlockchainWallet, Token, Transaction}
  alias ActivityLogger.System

  # TODO: handle failed transactions

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    attrs = Keyword.get(opts, :attrs, %{})
    GenServer.start_link(__MODULE__, attrs, name: name)
  end

  def init(%{interval: interval, blockchain: blockchain} = attrs) do
    adapter = BlockchainHelper.adapter()
    timer = Process.send_after(self(), :tick, interval)

    wallets = BlockchainWallet.get_by(type: "hot")
    tokens = Token.all_blockchain()
    blk_number = Transaction.get_last_blk_number(blockchain)

    attrs =
      attrs
      |> Map.put(:timer, timer)
      |> Map.put(:wallets, wallets)
      |> Map.put(:tokens, tokens)
      |> Map.put(:blk_number, blk_number)
      |> Map.put(:blk_retries, 0)

    {:ok, attrs}
  end

  def handle_info(:tick, %{interval: interval} = state) do
    new_state = run(state)
    timer = Process.send_after(self(), :tick, interval)
    {:noreply, %{new_state | timer: timer}}
  end

  defp run(
         %{
           blk_number: blk_number,
           blk_retries: blk_retries,
           blockchain: blockchain,
           addresses: addresses,
           contract_addresses: contract_addresses
         } = state
       ) do
    transaction_results =
      :get_transactions
      |> BlockchainHelper.adapter().call(%{
        blk_number: blk_number,
        addresses: addresses,
        contract_addresses: contract_addresses
      })
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

  defp insert(blockchain_transaction, %{blk_number: blk_number, blockchain: blockchain} = state) do
    case Transaction.get_by(%{
           blockchain_tx_hash: blockchain_transaction["tx_hash"],
           blockchain_identifier: blockchain
         }) do
      nil ->
        do_insert(blockchain_transaction, state)

      transaction ->
        :ok
    end
  end

  defp do_insert(blockchain_tx, %{blockchain: blockchain} = state) do
    token = Token.get_by(%{blockchain_address: blockchain_tx.contract_address})

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
      blockchain_metadata: blockchain_tx.data,
      from_token: token,
      to_token: token,
      # TODO: need to check if funds need to be added to an internal wallet
      to_wallet: nil,
      from_wallet: nil,
      from_blockchain_address: blockchain_tx.from,
      to_blockchain_address: blockchain_tx.to,
      from_account: nil,
      to_account: nil,
      from_user: nil,
      to_user: nil
    }

    # TODO: Notify websockets
    # TODO: Add value in local ledger
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
