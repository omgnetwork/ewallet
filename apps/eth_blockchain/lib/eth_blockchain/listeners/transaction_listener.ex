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
  A listener that polls a specific transaction from Ethereum. Can be started dynamically.
  """
  use GenServer, restart: :temporary
  require Logger

  alias EthBlockchain.{RootchainTransactionListener, ChildchainTransactionListener}

  @default_poll_interval 5000

  def start_link(attrs) do
    GenServer.start_link(__MODULE__, attrs)
  end

  #
  # Client API
  #

  @spec broadcast(any(), %{subscribers: [pid()]}) :: :ok
  def broadcast(msg, %{subscribers: subscribers}) do
    Enum.each(subscribers, fn subscriber_pid ->
      GenServer.cast(subscriber_pid, msg)
    end)
  end

  @spec set_interval(non_neg_integer(), GenServer.server()) :: :ok
  def set_interval(interval, pid) do
    GenServer.cast(pid, {:set_interval, interval})
  end

  #
  # GenServer callbacks
  #
  @impl true
  def init(
        %{
          id: hash,
          is_childchain_transaction: is_childchain_transaction,
          blockchain_adapter_pid: blockchain_adapter_pid,
          node_adapter: node_adapter
        } = attrs
      ) do
    # Notice we're not using Application.get_env/3 here for defaults? It's because we populate
    # this config from the database, which may return nil. This function then treats the nil
    # as an existing value, and so get_env/3 would never pick up the local defaults here.
    state = %{
      timer: nil,
      interval:
        Application.get_env(:eth_blockchain, :blockchain_transaction_poll_interval) ||
          @default_poll_interval,
      tx_hash: hash,
      transaction: nil,
      is_childchain_transaction: is_childchain_transaction,
      blockchain_adapter_pid: blockchain_adapter_pid,
      node_adapter: node_adapter,
      registry: attrs[:registry],
      subscribers: []
    }

    {:ok, state, {:continue, :start_polling}}
  end

  @impl true
  def handle_continue(:start_polling, state) do
    poll(state)
  end

  @impl true
  def handle_info(:poll, state) do
    poll(state)
  end

  @impl true
  def handle_call({:subscribe, subscriber_pid}, _from, %{subscribers: subscribers} = state) do
    case Enum.member?(subscribers, subscriber_pid) do
      true ->
        {:reply, {:error, :already_subscribed}, state}

      false ->
        state = Map.put(state, :subscribers, [subscriber_pid | subscribers])
        {:reply, :ok, state}
    end
  end

  @impl true
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

  @impl true
  def handle_cast({:set_interval, interval}, state) do
    state = %{state | interval: interval}

    # Cancel the existing timer if there's one
    _ = state.timer && Process.cancel_timer(state.timer)

    timer = schedule_next_poll(state)
    {:noreply, %{state | timer: timer}}
  end

  #
  # Polling management
  #

  defp poll(state) do
    new_state = run(state)
    timer = schedule_next_poll(new_state)

    {:noreply, %{new_state | timer: timer}}
  end

  defp schedule_next_poll(state) do
    case state.interval do
      interval when interval > 0 ->
        Process.send_after(self(), :poll, interval)

      interval ->
        _ =
          Logger.info(
            "Transaction listening for #{state.tx_hash} has paused" <>
              " because the interval is #{interval}."
          )

        nil
    end
  end

  #
  # Transaction listening
  #

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
end
