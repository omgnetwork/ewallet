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
  alias Ethereumex.HttpClient, as: Client

  def get_eth_syncing do
    handle_if_error(Client.eth_syncing())
  end

  def get_client_version do
    handle_if_error(Client.web3_client_version())
  end

  def get_network_id do
    handle_if_error(Client.net_version())
  end

  def get_peer_count do
    handle_if_error(Client.net_peer_count())
  end

  # Normalize the adapter error (if any) before returning the response.
  defp handle_if_error({:ok, _} = resp), do: resp
  defp handle_if_error({:error, error}), do: handle_error(error)
end
