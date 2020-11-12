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
        "omisego_plasma_framework_address" => "0xa72c9dceeef26c9d103d55c53d411c36f5cdf7ec",
        "omisego_eth_vault_address" => "0x2c7533f76567241341d1c27f0f239a20b6115714",
        "omisego_erc20_vault_address" => "0x2bed2ff4ee93a208edbf4185c7813103d8c4ab7f",
        "omisego_payment_exit_game_address" => "0x960ca6b9faa85118ba6badbe0097b1afd8827fac",
        "omisego_childchain_url" => "http://localhost:9656",
        "omisego_watcher_url" => "http://localhost:7534"
      }
    )

    :ok
  end
end
