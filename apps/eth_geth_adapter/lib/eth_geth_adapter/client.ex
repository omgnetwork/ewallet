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

defmodule EthGethAdapter.Client do
  @moduledoc false
  import EthGethAdapter.ErrorHandler
  import Utils.Helpers.Encoding
  alias Ethereumex.HttpClient, as: Client

  def get_eth_syncing do
    case Client.eth_syncing() do
      {:ok, %{}} -> true
      {:ok, false} -> false
      {:error, error} -> handle_error(error)
    end
  end

  def get_client_version do
    parse_through(Client.web3_client_version())
  end

  def get_network_id do
    parse_through(Client.net_version())
  end

  def get_peer_count do
    parse_to_int(Client.net_peer_count())
  end

  defp parse_through({:ok, data}), do: data
  defp parse_through({:error, error}), do: handle_error(error)

  defp parse_to_int({:ok, number}), do: int_from_hex(number)
  defp parse_to_int({:error, error}), do: handle_error(error)
end
