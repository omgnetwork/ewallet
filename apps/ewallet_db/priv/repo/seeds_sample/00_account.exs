# Copyright 2018 OmiseGO Pte Ltd
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

defmodule EWalletDB.Repo.Seeds.AccountSampleSeed do
  alias EWalletDB.Account
  alias EWalletDB.Seeder

  @seed_data [
    %{name: "brand1", description: "Brand 1", originator: %Seeder{}},
    %{name: "brand2", description: "Brand 2", originator: %Seeder{}},
    %{name: "branch1", description: "Branch 1", originator: %Seeder{}},
    %{name: "branch2", description: "Branch 2", originator: %Seeder{}}
  ]

  def seed do
    [
      run_banner: "Seeding sample accounts:",
      argsline: []
    ]
  end

  def run(writer, _args) do
    Enum.each(@seed_data, fn data ->
      run_with(writer, data)
    end)
  end

  defp run_with(writer, data) do
    case Account.get_by(name: data.name) do
      nil ->
        case Account.insert(data) do
          {:ok, account} ->
            writer.success("""
              Name   : #{account.name}
              ID     : #{account.id}
            """)

          {:error, changeset} ->
            writer.error("  The account #{data.name} could not be inserted:")
            writer.print_errors(changeset)

          _ ->
            writer.error("  The account #{data.name} could not be inserted:")
            writer.error("  Unknown error.")
        end

      %Account{} = account ->
        writer.warn("""
          Name   : #{account.name}
          ID     : #{account.id}
        """)
    end
  end
end
