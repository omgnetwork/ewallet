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

defmodule EthBlockchain.NonceRegistry do
  @moduledoc """
  The Blockchain registry handles the lifecycle of nonce handlers.
  """
  use GenServer

  alias EthBlockchain.Nonce

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, [], name: name)
  end

  @impl true
  def init(_args) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:lookup, address, node_adapter, blockchain_adapter_pid}, _from, registry) do
    case registry[address] do
      nil ->
        start_and_register(registry, node_adapter, blockchain_adapter_pid, address)

      pid ->
        case Process.alive?(pid) do
          true ->
            {:reply, {:ok, pid}, registry}

          false ->
            start_and_register(registry, node_adapter, blockchain_adapter_pid, address)
        end
    end
  end

  def lookup(address, node_adapter, blockchain_adapter_pid, pid \\ __MODULE__) do
    GenServer.call(pid, {:lookup, address, node_adapter, blockchain_adapter_pid})
  end

  defp start_and_register(registry, node_adapter, blockchain_adapter_pid, address) do
    with {:ok, pid} <- start_handler(address, node_adapter, blockchain_adapter_pid),
         registry <- Map.put(registry, address, pid) do
      {:reply, {:ok, pid}, registry}
    else
      error ->
        {:reply, error, registry}
    end
  end

  defp start_handler(address, node_adapter, blockchain_adapter_pid) do
    DynamicSupervisor.start_child(
      EthBlockchain.DynamicNonceSupervisor,
      {Nonce,
       [
         args: %{
           address: address,
           node_adapter: node_adapter,
           blockchain_adapter_pid: blockchain_adapter_pid
         }
       ]}
    )
  end
end
