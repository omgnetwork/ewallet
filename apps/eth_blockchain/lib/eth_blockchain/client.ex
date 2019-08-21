# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EthBlockchain.Client do
  @moduledoc """
  The module for interacting with Ethereum's client-related calls.
  """
  alias EthBlockchain.Adapter
  import Utils.Helpers.Encoding

  def get_eth_syncing(adapter \\ nil, pid \\ nil) do
    case Adapter.call({:get_eth_syncing}, adapter, pid) do
      {:ok, %{}} -> {:ok, true}
      {:ok, false} -> {:ok, false}
      error -> error
    end
  end

  def get_client_version(adapter \\ nil, pid \\ nil) do
    Adapter.call({:get_client_version}, adapter, pid)
  end

  def get_network_id(adapter \\ nil, pid \\ nil) do
    Adapter.call({:get_network_id}, adapter, pid)
  end

  def get_peer_count(adapter \\ nil, pid \\ nil) do
    case Adapter.call({:get_peer_count}, adapter, pid) do
      {:ok, number} -> {:ok, int_from_hex(number)}
      error -> error
    end
  end
end
