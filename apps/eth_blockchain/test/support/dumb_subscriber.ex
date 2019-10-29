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

defmodule EthBlockchain.DumbSubscriber do
  @moduledoc """
  Acts as a subscriber to test the transaction listener.
  """
  use GenServer, restart: :temporary
  require Logger

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    {:ok, Map.put(state, :count, 0)}
  end

  def handle_cast(
        {:confirmations_count, tx_hash, block_number},
        %{count: count, subscriber: pid} = state
      ) do
    state =
      state
      |> Map.put(:tx_hash, tx_hash)
      |> Map.put(:block_number, block_number)

    case count > 1 do
      true ->
        Process.send(pid, state, [:noconnect])
        {:noreply, state}

      false ->
        {:noreply, Map.put(state, :count, count + 1)}
    end
  end

  def handle_cast({:failed_transaction}, %{count: count, subscriber: pid} = state) do
    case count > -1 do
      true ->
        Process.send(pid, state, [:noconnect])
        {:noreply, state}

      false ->
        {:noreply, Map.put(state, :count, count + 1)}
    end
  end

  def handle_cast({:not_found}, %{count: count, subscriber: pid} = state) do
    # If we have a `retry_not_found_count` in the state, we will increase the count by 1
    # until we reach this `retry_not_found_count` at which point we send put an error in the
    # state and we send it back to the subscriber.
    #
    # This is especially usefull in integration tests as it follows this flow:
    # - A transaction is created but not yet included in a block
    #  -> The TransactionListener will broadcast `:not_found` events when polling for the receipt
    #     until the transaction is actually included in the block. When testing for a valid
    #     transaction, we don't want to receive the `:not_found` event, but instead just wait
    #     until we receive a valid transaction.
    # - The transaction gets included in a block
    #  - > The TransactionListener will broadcast `:confirmations_count` events
    retry_not_found_count = state[:retry_not_found_count] || -1

    case count > retry_not_found_count do
      true ->
        state = Map.put(state, :error, :not_found)
        Process.send(pid, state, [:noconnect])
        {:noreply, state}

      _ ->
        {:noreply, Map.put(state, :count, count + 1)}
    end
  end

  def handle_cast({:adapter_error, error}, %{count: count, subscriber: pid} = state) do
    state = Map.put(state, :error, error)

    case count > -1 do
      true ->
        Process.send(pid, state, [:noconnect])
        {:noreply, state}

      false ->
        {:noreply, Map.put(state, :count, count + 1)}
    end
  end
end
