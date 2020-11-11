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
    [
      run_banner: "Updating blockchain settings",
      argsline: []
    ]
  end

  def run(writer, _args) do
    {:ok, [blockchain_enabled: {:ok, _}]} =
      Config.update(%{
        blockchain_enabled: true,
        originator: %Seeder{}
      })
    writer.success("Setting `blockchain_enabled` to true")

    {:ok, [internal_enabled: {:ok, _}]} =
      Config.update(%{
        internal_enabled: false,
        originator: %Seeder{}
      })
    writer.success("Setting `internal_enabled` to false")

    {:ok, [blockchain_chain_id: {:ok, _}]} =
      Config.update(%{
        blockchain_chain_id: 1337,
        originator: %Seeder{}
      })
    writer.success("Setting `blockchain_chain_id` to 1337")
  end
end
