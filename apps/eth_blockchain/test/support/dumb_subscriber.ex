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
        {:confirmations_count, receipt, confirmations_count},
        %{count: count, subscriber: pid} = state
      ) do
    state =
      state
      |> Map.put(:receipt, receipt)
      |> Map.put(:confirmations_count, confirmations_count)
      |> Map.put(:error, nil)

    case count > 1 do
      true ->
        Process.send(pid, state, [:noconnect])
        {:noreply, state}

      false ->
        {:noreply, Map.put(state, :count, count + 1)}
    end
  end

  def handle_cast({:failed_transaction, receipt}, %{count: count, subscriber: pid} = state) do
    state = Map.put(state, :receipt, receipt)

    case count > -1 do
      true ->
        Process.send(pid, state, [:noconnect])
        {:noreply, state}

      false ->
        {:noreply, Map.put(state, :count, count + 1)}
    end
  end

  def handle_cast(
        {:not_found},
        %{count: count, subscriber: pid, retry_not_found_count: retry_not_found_count} = state
      ) do
    state = Map.put(state, :error, :not_found)

    case count > retry_not_found_count do
      true ->
        Process.send(pid, state, [:noconnect])
        {:noreply, state}

      _ ->
        {:noreply, Map.put(state, :count, count + 1)}
    end
  end

  def handle_cast({:not_found}, %{count: count, subscriber: pid} = state) do
    state = Map.put(state, :error, :not_found)

    case count > -1 do
      true ->
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
