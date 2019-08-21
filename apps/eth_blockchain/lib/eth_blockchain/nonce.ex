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
  use GenServer, restart: :temporary

  import Utils.Helpers.Encoding

  alias EthBlockchain.Adapter

  def start_link(opts) do
    args = Keyword.get(opts, :args, %{})
    GenServer.start_link(__MODULE__, args)
  end

  def init(%{
        address: address,
        node_adapter: node_adapter,
        blockchain_adapter_pid: blockchain_adapter_pid
      }) do
    case get_nonce(address, node_adapter, blockchain_adapter_pid) do
      {:ok, nonce} ->
        {:ok,
         %{
           address: address,
           nonce: nonce,
           node_adapter: node_adapter,
           blockchain_adapter_pid: blockchain_adapter_pid
         }}

      {:error, error} ->
        {:stop, error}
    end
  end

  def handle_call(:next_nonce, _from, %{nonce: nonce} = state) do
    {:reply, {:ok, nonce}, Map.put(state, :nonce, nonce + 1)}
  end

  def handle_call(
        :force_refresh,
        _from,
        %{
          address: address,
          node_adapter: node_adapter,
          blockchain_adapter_pid: blockchain_adapter_pid
        } = state
      ) do
    case get_nonce(address, node_adapter, blockchain_adapter_pid) do
      {:ok, nonce} ->
        {:reply, {:ok, nonce}, Map.put(state, :nonce, nonce)}

      {:error, error} ->
        {:stop, error}
    end
  end

  # Client API
  @doc """
  Get the nonce to use for the next transaction.
  """
  def next_nonce(pid \\ __MODULE__) do
    GenServer.call(pid, :next_nonce)
  end

  @doc """
  Force the refresh of a nonce for the given address by checking the current transaction count
  for the address.
  """
  def force_refresh(pid \\ __MODULE__) do
    GenServer.call(pid, :force_refresh)
  end

  defp get_nonce(address, eth_node_adapter, eth_node_adapter_pid) do
    with {:ok, nonce} <-
           Adapter.call(
             {:get_transaction_count, address, "pending"},
             eth_node_adapter: eth_node_adapter,
             eth_node_adapter_pid: eth_node_adapter_pid
           ) do
      {:ok, int_from_hex(nonce)}
    end
  end
end
