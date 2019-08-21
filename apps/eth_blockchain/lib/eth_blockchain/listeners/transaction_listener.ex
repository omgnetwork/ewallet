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

  alias EthBlockchain.{Block, TransactionReceipt}

  def start_link(attrs) do
    GenServer.start_link(__MODULE__, attrs)
  end

  def init(
        %{
          id: hash,
          interval: interval,
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
           tx_hash: tx_hash,
           blockchain_adapter_pid: blockchain_adapter_pid,
           node_adapter: node_adapter
         } = state
       ) do
    case TransactionReceipt.get(%{tx_hash: tx_hash},
           eth_node_adapter: node_adapter,
           eth_node_adapter_pid: blockchain_adapter_pid
         ) do
      {:ok, :success, receipt} ->
        confirmations_count = Block.get_number() - receipt.block_number + 1
        broadcast({:confirmations_count, receipt, confirmations_count}, state)
        state

      {:ok, :failed, receipt} ->
        broadcast({:failed_transaction, receipt}, state)
        state

      {:ok, :not_found, nil} ->
        # Do nothing for now. TODO: increase checking interval until maximum is reached?
        broadcast({:not_found}, state)
        state

      {:error, :adapter_error, message} ->
        broadcast({:adapter_error, message}, state)
        state

      {:error, error} ->
        broadcast({:adapter_error, error}, state)
        state
    end
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
