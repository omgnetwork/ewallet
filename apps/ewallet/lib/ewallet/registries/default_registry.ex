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

defmodule EWallet.DefaultRegistry do
  @moduledoc """
  This module manages the lifecycle of the trackers.
  Currently, only a transaction tracker is available.
  """
  use GenServer

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  def handle_call({:get_registry}, _from, registry) do
    {:reply, registry, registry}
  end

  def handle_call({:lookup, uuid}, _from, registry) do
    case Map.fetch(registry, uuid) do
      :error ->
        {:reply, {:error, :not_found}, registry}

      res ->
        {:reply, res, registry}
    end
  end

  @impl true
  def handle_call(
        {:track, tracker, attrs},
        _from,
        registry
      ) do
    if Map.has_key?(registry, attrs[:id]) do
      {:reply, :ok, registry}
    else
      {:ok, pid} =
        DynamicSupervisor.start_child(
          EWallet.DynamicListenerSupervisor,
          {tracker, Map.merge(attrs, %{registry: self()})}
        )

      {:reply, :ok,
       Map.put(registry, attrs[:id], %{
         tracker: tracker,
         pid: pid
       })}
    end
  end

  @impl true
  def handle_cast({:stop_tracker, id}, registry) do
    if Map.has_key?(registry, id) do
      :ok =
        DynamicSupervisor.terminate_child(EWallet.DynamicListenerSupervisor, registry[id][:pid])

      {:noreply, Map.delete(registry, id)}
    else
      {:noreply, registry}
    end
  end

  def get_registry(pid \\ __MODULE__) do
    GenServer.call(pid, {:get_registry})
  end

  def lookup(id, pid \\ __MODULE__) do
    GenServer.call(pid, {:lookup, id})
  end

  def start_tracker(tracker, attrs, pid \\ __MODULE__) do
    GenServer.call(pid, {:track, tracker, attrs})
  end
end
