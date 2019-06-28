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
  use GenServer, restart: :temporary

  alias EthBlockchain.{Block, TransactionReceipt}

  def start_link(attrs) do
    GenServer.start_link(__MODULE__, attrs)
  end

  def init(%{
        id: hash,
        interval: interval,
        blockchain_adapter_pid: blockchain_adapter_pid,
        node_adapter: node_adapter
      }) do
    timer = Process.send_after(self(), :tick, interval)

    {:ok,
     %{
       timer: timer,
       interval: interval,
       tx_hash: hash,
       transaction: nil,
       blockchain_adapter_pid: blockchain_adapter_pid,
       node_adapter: node_adapter,
       subscribers: []
     }}
  end

  def handle_info(:tick, %{interval: interval} = state) do
    new_state = run(state)
    timer = Process.send_after(self(), :tick, interval)
    {:noreply, %{new_state | timer: timer}}
  end

  def handle_info(msg, a) do
    {:noreply, a}
  end

  def handle_cast({:unsubscribe, subscriber_pid}, %{subscribers: subscribers} = state) do
    subscribers = List.delete(subscribers, subscriber_pid)

    case length(subscribers) == 0 do
      true ->
        {:stop, :normal, %{state | subscribers: subscribers}}

      false ->
        {:noreply, %{state | subscribers: subscribers}}
    end
  end

  defp run(
         %{
           subscribers: subscribers,
           tx_hash: tx_hash,
           blockchain_adapter_pid: blockchain_adapter_pid,
           node_adapter: node_adapter
         } = state
       ) do
    case TransactionReceipt.get(%{tx_hash: tx_hash}, node_adapter, blockchain_adapter_pid) do
      {:ok, :success, receipt} ->
        # emit confs
        confirmations_count = Block.get_number() - receipt.block_number + 1

        Enum.each(subscribers, fn subscriber_pid ->
          GenServer.cast(subscriber_pid, {:confirmations_count, tx_hash, confirmations_count})
        end)

        state

      {:ok, :failed, receipt} ->
        # TODO: emit failure
        state

      a ->
        # TODO
        IO.inspect(a)
        state
    end
  end

  # handle push & update
  def handle_call({:subscribe, subscriber_pid}, _from, %{subscribers: subscribers} = state) do
    state = Map.put(state, :subscribers, [subscriber_pid | subscribers])
    {:reply, :ok, state}
  end

  def subscribe(listener_pid, subscriber_pid) do
    GenServer.call(listener_pid, {:subscribe, subscriber_pid})
  end

  def unsubscribe(listener_pid, subscriber_pid) do
    GenServer.cast(listener_pid, {:unsubscribe, subscriber_pid})
  end
end
