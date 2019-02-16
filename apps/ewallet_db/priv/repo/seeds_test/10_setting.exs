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

# credo:disable-for-this-file
defmodule EWalletDB.Repo.Seeds.SettingsSeed do
  alias EWalletDB.Seeder
  alias EWalletConfig.{Config, Setting}

  def seed do
    [
      run_banner: "Updating settings",
      argsline: [],
    ]
  end

  def run(writer, _args) do
    {:ok, [enable_standalone: {:ok, %Setting{}}]} = Config.update(%{
      enable_standalone: true,
      originator: %Seeder{}
    })

    writer.warn("""
      Enable standalone : #{Config.get(:enable_standalone)}
    """)
  end
end
