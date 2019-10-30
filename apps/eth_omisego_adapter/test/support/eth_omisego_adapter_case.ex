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

defmodule EthOmiseGOAdapter.EthOmiseGOAdapterCase do
  @moduledoc false
  use ExUnit.CaseTemplate
  alias Ecto.Adapters.SQL.Sandbox
  alias EWalletConfig.ConfigTestHelper

  using do
    quote do
      import EthOmiseGOAdapter.EthOmiseGOAdapterCase
    end
  end

  setup tags do
    :ok = Sandbox.checkout(ActivityLogger.Repo)
    :ok = Sandbox.checkout(EWalletConfig.Repo)
    :ok = Sandbox.checkout(Keychain.Repo)

    unless tags[:async] do
      Sandbox.mode(ActivityLogger.Repo, {:shared, self()})
      Sandbox.mode(EWalletConfig.Repo, {:shared, self()})
      Sandbox.mode(Keychain.Repo, {:shared, self()})
    end

    config_pid = start_supervised!(EWalletConfig.Config)

    ConfigTestHelper.restart_config_genserver(
      self(),
      config_pid,
      EWalletConfig.Repo,
      [:eth_omisego_adapter],
      %{
        "omisego_rootchain_contract_address" => "0x316d3e9d574e91fd272fd24fb5cb7dfd4707a571",
        "omisego_childchain_url" => "http://localhost:8082",
        "omisego_watcher_url" => "http://localhost:8081"
      }
    )

    :ok
  end
end
