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

# credo:disable-for-this-file
defmodule EWalletDB.Repo.Seeds.RoleSeed do
  alias EWalletDB.Role
  alias EWalletDB.Seeder

  @seed_data [
    %{name: "admin", display_name: "Admin", originator: %Seeder{}},
    %{name: "viewer", display_name: "Viewer", originator: %Seeder{}},
  ]

  def seed do
    [
      run_banner: "Seeding roles",
      argsline: [],
    ]
  end

  def run(writer, _args) do
    Enum.each @seed_data, fn data ->
      run_with(writer, data)
    end
  end

  defp run_with(writer, data) do
    case Role.get_by(name: data.name) do
      nil ->
        case Role.insert(data) do
          {:ok, role} ->
            writer.success("""
              Name         : #{role.name}
              Display name : #{role.display_name}
            """)
          {:error, changeset} ->
            writer.error("  Role #{data.name} could not be inserted:")
            writer.print_errors(changeset)
          _ ->
            writer.error("  Role #{data.name} could not be inserted:")
            writer.error("  Unknown error.")
        end
      %Role{} = role ->
        writer.warn("""
          Name         : #{role.name}
          Display name : #{role.display_name}
        """)
    end
  end
end
