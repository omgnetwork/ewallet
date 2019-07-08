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

    {:ok, attrs}
  end

  def handle_info(:tick, %{interval: interval} = state) do
    new_state = run(state)
    timer = Process.send_after(self(), :tick, interval)
    {:noreply, %{new_state | timer: timer}}
  end

  defp run(%{blk_number: blk_number, blockchain: blockchain} = state) do
    BlockchainHelper.adapter().call(:get_transactions, %{
      blk_number: blk_number,
      addresses: addresses,
      contract_addresses: contract_addresses
    })

    # get from blockchain app list of txs
    # insert / process
    # count tx with blk number == returned value from beginning / requery
    # if true
    # set timer, blk number + 1
    # if false
    # set time, blk number
  end
end
