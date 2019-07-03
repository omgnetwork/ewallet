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

defmodule EthBlockchain.DumbListener do
  use GenServer, restart: :temporary

  def start_link(attrs) do
    GenServer.start_link(__MODULE__, attrs)
  end

  def init(attrs) do
    {:ok, Map.put(attrs, :subscribers, [])}
  end

  def handle_call({:get_state}, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:subscribe, subscriber_pid}, _from, %{subscribers: subscribers} = state) do
    state = Map.put(state, :subscribers, [subscriber_pid | subscribers])
    {:reply, :ok, state}
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
end
