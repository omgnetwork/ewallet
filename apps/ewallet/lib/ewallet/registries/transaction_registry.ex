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

defmodule EWallet.TransactionRegistry do
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
  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:get_registry}, _from, registry) do
    {:reply, registry, registry}
  end

  def handle_call({:lookup, uuid}, _from, registry) do
    {:reply, Map.fetch(registry, uuid), registry}
  end

  @impl true
  def handle_call({:track, tracker, transaction}, _from, registry) do
    if Map.has_key?(registry, transaction.uuid) do
      {:reply, :ok, registry}
    else
      {:ok, pid} =
        DynamicSupervisor.start_child(EWallet.DynamicListenerSupervisor, {tracker, transaction})

      {:reply, :ok,
       Map.put(registry, transaction.uuid, %{
         tracker: tracker,
         pid: pid
       })}
    end
  end

  def get_registry(pid \\ __MODULE__) do
    GenServer.call(pid, {:get_registry})
  end

  def lookup(uuid, pid \\ __MODULE__) do
    GenServer.call(pid, {:lookup, uuid})
  end

  def start_tracker(tracker, transaction, pid \\ __MODULE__) do
    GenServer.call(pid, {:track, tracker, transaction})
  end
end
