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

defmodule EthBlockchain.TransactionListener do
  @moduledoc """
  Listener started dynamically to poll a specific transaction from Ethereum.
  """
  use GenServer, restart: :temporary

  alias EthBlockchain.{RootchainTransactionListener, ChildchainTransactionListener}

  def start_link(attrs) do
    GenServer.start_link(__MODULE__, attrs)
  end

  def init(
        %{
          id: hash,
          interval: interval,
          is_childchain_transaction: is_childchain_transaction,
          blockchain_adapter_pid: blockchain_adapter_pid,
          node_adapter: node_adapter
        } = attrs
      ) do
    {:ok,
     %{
       timer: nil,
       interval: interval,
       tx_hash: hash,
       transaction: nil,
       is_childchain_transaction: is_childchain_transaction,
       blockchain_adapter_pid: blockchain_adapter_pid,
       node_adapter: node_adapter,
       registry: attrs[:registry],
       subscribers: []
     }, {:continue, :start_polling}}
  end

  def handle_continue(:start_polling, state) do
    poll(state)
  end

  def handle_info(:poll, state) do
    poll(state)
  end

  defp poll(%{interval: interval} = state) do
    new_state = run(state)
    timer = Process.send_after(self(), :poll, interval)
    {:noreply, %{new_state | timer: timer}}
  end

  defp run(
         %{
           is_childchain_transaction: false,
           tx_hash: tx_hash,
           blockchain_adapter_pid: blockchain_adapter_pid,
           node_adapter: node_adapter
         } = state
       ) do
    tx_hash
    |> RootchainTransactionListener.broadcast_payload(node_adapter, blockchain_adapter_pid)
    |> broadcast(state)

    state
  end

  defp run(
         %{
           is_childchain_transaction: true,
           tx_hash: tx_hash,
           blockchain_adapter_pid: blockchain_adapter_pid,
           node_adapter: node_adapter
         } = state
       ) do
    tx_hash
    |> ChildchainTransactionListener.broadcast_payload(node_adapter, blockchain_adapter_pid)
    |> broadcast(state)

    state
  end

  def broadcast(msg, %{subscribers: subscribers}) do
    Enum.each(subscribers, fn subscriber_pid ->
      GenServer.cast(subscriber_pid, msg)
    end)
  end

  def handle_call({:subscribe, subscriber_pid}, _from, %{subscribers: subscribers} = state) do
    case Enum.member?(subscribers, subscriber_pid) do
      true ->
        {:reply, {:error, :already_subscribed}, state}

      false ->
        state = Map.put(state, :subscribers, [subscriber_pid | subscribers])
        {:reply, :ok, state}
    end
  end

  def handle_cast({:unsubscribe, subscriber_pid}, %{subscribers: subscribers} = state) do
    subscribers = List.delete(subscribers, subscriber_pid)

    case Enum.empty?(subscribers) do
      true ->
        case is_nil(state[:registry]) do
          true ->
            {:stop, :normal, %{state | subscribers: subscribers}}

          false ->
            :ok = GenServer.cast(state[:registry], {:stop_listener, state[:tx_hash]})
            {:noreply, %{state | subscribers: subscribers}}
        end

      false ->
        {:noreply, %{state | subscribers: subscribers}}
    end
  end
end
