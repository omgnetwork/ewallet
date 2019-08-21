# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EthGethAdapter.Worker do
  @moduledoc false

  alias EthGethAdapter.{Balance, Block, Transaction, Token, ErrorHandler, TransactionReceipt}

  @type server :: GenServer.server()
  @typep from :: GenServer.from()
  @typep state :: nil
  @typep resp(ret) :: ret | {:error, atom()}
  @typep reply(ret) :: {:reply, resp(ret), state()}

  ## Genserver
  ##

  use GenServer

  @doc """
  Starts EthGethAdapter.Worker.
  """
  @spec start_link() :: GenServer.on_start()
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    DeferredConfig.populate(:ethereumex)
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Initialize the registry.
  """
  @spec init(:ok) :: {:ok, nil}
  def init(:ok) do
    {:ok, nil}
  end

  @doc """
  Stops EthGethAdapter.Worker.
  """
  @spec stop() :: :ok
  @spec stop(server()) :: :ok
  def stop(pid \\ __MODULE__) do
    GenServer.stop(pid)
  end

  ## Callbacks
  ##

  @doc """
  Handles the genserver calls.
  """
  @spec handle_call(tuple(), from(), state()) ::
          reply({:ok, map()}) | reply({:error, any()})
  def handle_call(
        {:get_balances, address, contract_addresses, encoded_abi_data, block},
        _from,
        reg
      ) do
    {:reply, Balance.get(address, contract_addresses, encoded_abi_data, block), reg}
  end

  def handle_call({:send_raw, transaction_data}, _from, reg) do
    {:reply, Transaction.send_raw(transaction_data), reg}
  end

  def handle_call({:get_transaction_count, address, block}, _from, reg) do
    {:reply, Transaction.get_transaction_count(address, block), reg}
  end

  def handle_call({:get_transaction_receipt, transaction_hash}, _from, reg) do
    {:reply, TransactionReceipt.get(transaction_hash), reg}
  end

  def handle_call({:get_block_number}, _from, reg) do
    {:reply, Block.get_number(), reg}
  end

  def handle_call({:get_block, number}, _from, reg) do
    {:reply, Block.get(number), reg}
  end

  def handle_call({:get_field, contract_address, encoded_abi_data}, _from, reg) do
    {:reply, Token.get_field(contract_address, encoded_abi_data), reg}
  end

  def handle_call({:get_errors}, _from, reg) do
    {:reply, ErrorHandler.errors(), reg}
  end
end
