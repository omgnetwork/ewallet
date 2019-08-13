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

defmodule EthBlockchain.Nonce do
  @moduledoc """
  Keep track of the nonce to use for each address. Refresh from transaction count if necessary.
  Note that the nonce stored in the state is the nonce to use for the next transaction.

  For example, given an empty state `%{}` and the address Alice: "0x811ae0a85d3f86824da3abe49a2407ea55a8b053"
  with 52 transactions already sent:
  The first call to next_nonce/4 will not find Alice in the state, so it will query the RPC API that will
  return a count of 52 transactions, next_nonce/4 will then return this count with {:ok, 52} and
  will set the next nonce to use for Alice in its state (53).
  """
  use GenServer

  import Utils.Helpers.Encoding

  alias EthBlockchain.Adapter

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, %{}, name: name)
  end

  def init(_args) do
    {:ok, %{}}
  end

  def handle_call({:next_nonce, address, node_adapter, blockchain_adapter_pid}, _from, state) do
    case Map.get(state, address) do
      nil ->
        refresh_nonce(address, true, node_adapter, blockchain_adapter_pid, state)

      nonce ->
        {:reply, {:ok, nonce}, Map.put(state, address, nonce + 1)}
    end
  end

  def handle_call({:force_refresh, address, node_adapter, blockchain_adapter_pid}, _from, state) do
    refresh_nonce(address, false, node_adapter, blockchain_adapter_pid, state)
  end

  # Client API
  @doc """
  Get the nonce to use for the next transaction.
  If the address is not found in the state, query the RPC API to get the current transaction count
  for this address and returns it.
  Save the next nonce to use in the state when called.
  """
  def next_nonce(address, node_adapter \\ nil, blockchain_adapter_pid \\ nil, pid \\ __MODULE__) do
    GenServer.call(pid, {:next_nonce, address, node_adapter, blockchain_adapter_pid})
  end

  @doc """
  Force the refresh of a nonce for the given address by checkcing the current transaction count
  for the address.
  """
  def force_refresh(
        address,
        node_adapter \\ nil,
        blockchain_adapter_pid \\ nil,
        pid \\ __MODULE__
      ) do
    GenServer.call(pid, {:force_refresh, address, node_adapter, blockchain_adapter_pid})
  end

  # Private functions
  defp refresh_nonce(address, increment_nonce, node_adapter, blockchain_adapter_pid, state) do
    case get_transaction_count(address, node_adapter, blockchain_adapter_pid) do
      {:ok, nonce} ->
        state_nonce =
          case increment_nonce do
            true -> nonce + 1
            false -> nonce
          end

        {:reply, {:ok, nonce}, Map.put(state, address, state_nonce)}

      error ->
        {:reply, error, state}
    end
  end

  defp get_transaction_count(address, node_adapter, blockchain_adapter_pid) do
    case Adapter.call({:get_transaction_count, address}, node_adapter, blockchain_adapter_pid) do
      {:ok, nonce} ->
        {:ok, int_from_hex(nonce)}

      error ->
        error
    end
  end
end
