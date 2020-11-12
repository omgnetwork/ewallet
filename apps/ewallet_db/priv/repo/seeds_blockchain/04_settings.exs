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

defmodule EWalletDB.Repo.Seeds.BlockchainSetting do
  alias EWalletDB.Seeder
  alias EWalletConfig.Config

  def seed do
    settings = Enum.into(Config.settings(), %{}, fn s -> {s.key, s} end)

    [
      run_banner: "Updating blockchain settings",
      argsline: [
        {:title, "Input the blockchain environment variables corresponding to your setup. Leave blank for default."},
        {:input, {:boolean, :internal_enabled, settings["internal_enabled"].description, settings["internal_enabled"].value}},
        {:input, {:text, :blockchain_json_rpc_url, settings["blockchain_json_rpc_url"].description, settings["blockchain_json_rpc_url"].value}},
        {:input, {:integer, :blockchain_chain_id, settings["blockchain_chain_id"].description, settings["blockchain_chain_id"].value}},
        {:input, {:integer, :blockchain_default_gas_price, settings["blockchain_default_gas_price"].description, settings["blockchain_default_gas_price"].value}},
        {:input, {:integer, :blockchain_confirmations_threshold, settings["blockchain_confirmations_threshold"].description, settings["blockchain_confirmations_threshold"].value}},
        {:input, {:text, :omisego_plasma_framework_address, settings["omisego_plasma_framework_address"].description, settings["omisego_plasma_framework_address"].value}},
        {:input, {:text, :omisego_eth_vault_address, settings["omisego_eth_vault_address"].description, settings["omisego_eth_vault_address"].value}},
        {:input, {:text, :omisego_erc20_vault_address, settings["omisego_erc20_vault_address"].description, settings["omisego_erc20_vault_address"].value}},
        {:input, {:text, :omisego_payment_exit_game_address, settings["omisego_payment_exit_game_address"].description, settings["omisego_payment_exit_game_address"].value}},
        {:input, {:text, :omisego_childchain_url, settings["omisego_childchain_url"].description, settings["omisego_childchain_url"].value}},
        {:input, {:text, :omisego_watcher_url, settings["omisego_watcher_url"].description, settings["omisego_watcher_url"].value}},
      ]
    ]
  end

  def run(writer, args) do
    args
    |> Enum.into(%{})
    |> Map.put(:blockchain_enabled, true)
    |> Map.put(:originator, %Seeder{})
    |> Config.update()
    |> IO.inspect()
    |> case do
      {:ok, _} ->
        writer.success("successfully updated config")
      _ ->
        writer.error("failed to update config")
    end

  end
end
