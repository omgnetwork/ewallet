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

defmodule EthGethAdapter.Application do
  @moduledoc false
  use Application
  alias EWalletConfig.Config

  @doc """
  Starts `EthGethAdapter.Application`. Although, it doesn't start any child process.
  `EthGethAdapter` code get started/called by other subapps, but we still need
  this `EthGethAdapter.Application.start/2` to do configurations at startup.
  """
  def start(_type, _args) do
    settings = Application.get_env(:eth_geth_adapter, :settings)
    _ = Config.register_and_load(:eth_geth_adapter, settings)
    _ = config_ethereumex()

    children = []
    Supervisor.start_link(children, name: EthGethAdapter.Supervisor, strategy: :one_for_one)
  end

  # Takes relevant ewallet's configs and set them into :ethereumex application configs
  defp config_ethereumex do
    json_rpc_url = Application.get_env(:eth_geth_adapter, :blockchain_json_rpc_url)

    :ok = Application.put_env(:ethereumex, :url, json_rpc_url)
    :ok = Application.put_env(:ethereumex, :client_type, :http)

    :ok
  end
end
