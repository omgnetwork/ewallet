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

defmodule EWallet.TestEndpoint do
  @moduledoc """
  Test endpoint used to check if event broadcasts are properly received.
  """
  use Agent

  def start_link do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def stop do
    Agent.stop(__MODULE__)
  end

  def get_events do
    Agent.get(__MODULE__, fn list -> list end)
  end

  def broadcast(topic, event, payload) do
    Agent.get_and_update(__MODULE__, fn list ->
      updated =
        list ++
          [
            %{
              topic: topic,
              event: event,
              payload: payload
            }
          ]

      {list, updated}
    end)
  end
end
