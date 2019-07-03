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

defmodule EthBlockchain.BlockchainRegistry do
  use GenServer

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:lookup, id}, _from, registry) do
    {:reply, Map.fetch(registry, id), registry}
  end

  @impl true
  def handle_call({:start_listener, listener, attrs}, _from, registry) do
    if Map.has_key?(registry, attrs[:id]) do
      {:reply, :ok, registry}
    else
      {:ok, pid} =
        DynamicSupervisor.start_child(EthBlockchain.DynamicListenerSupervisor, {listener, attrs})

      {:reply, :ok,
       Map.put(registry, attrs[:id], %{
         listener: listener,
         pid: pid
       })}
    end
  end

  def handle_call({:subscribe, id, subscriber_pid}, _from, registry) do
    case Map.has_key?(registry, id) do
      true ->
        pid = Map.fetch!(registry, id)[:pid]
        :ok = GenServer.call(pid, {:subscribe, subscriber_pid})
        {:reply, :ok, registry}

      false ->
        {:reply, {:error, :not_found}, registry}
    end
  end

  def handle_call({:unsubscribe, id, subscriber_pid}, _from, registry) do
    case Map.has_key?(registry, id) do
      true ->
        pid = Map.fetch!(registry, id)[:pid]
        :ok = GenServer.cast(pid, {:unsubscribe, subscriber_pid})
        {:reply, :ok, registry}

      false ->
        {:reply, {:error, :not_found}, registry}
    end
  end

  def lookup(id, pid \\ __MODULE__) do
    GenServer.call(pid, {:lookup, id})
  end

  def start_listener(listener, attrs, pid \\ __MODULE__) do
    GenServer.call(pid, {:start_listener, listener, attrs})
  end

  def subscribe(id, subscriber_pid, pid \\ __MODULE__) do
    GenServer.call(pid, {:subscribe, id, subscriber_pid})
  end

  def unsubscribe(id, subscriber_pid, pid \\ __MODULE__) do
    GenServer.call(pid, {:unsubscribe, id, subscriber_pid})
  end
end
