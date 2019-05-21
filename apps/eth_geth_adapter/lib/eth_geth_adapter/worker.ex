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

  alias EthGethAdapter.{Balance, Transaction}

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

  def handle_call({:send, transaction_data}, _from, reg) do
    {:reply, Transaction.send(transaction_data), reg}
  end

  def handle_call({:get_transaction_count, address}, _from, reg) do
    {:reply, Transaction.get_transaction_count(address), reg}
  end
end
