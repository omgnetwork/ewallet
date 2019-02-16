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

defmodule EWalletDB.Repo.Seeds.AdminPanelUserSampleSeed do
  import Utils.Helpers.Crypto, only: [generate_base64_key: 1]
  alias EWalletDB.User
  alias EWalletDB.Seeder

  @seed_data [
    %{
      email: "admin_brand1@example.com",
      password: generate_base64_key(16),
      metadata: %{},
      is_admin: true,
      originator: %Seeder{}
    },
    %{
      email: "admin_branch1@example.com",
      password: generate_base64_key(16),
      metadata: %{},
      is_admin: true,
      originator: %Seeder{}
    },
    %{
      email: "viewer_master@example.com",
      password: generate_base64_key(16),
      metadata: %{},
      is_admin: true,
      originator: %Seeder{}
    },
    %{
      email: "viewer_brand1@example.com",
      password: generate_base64_key(16),
      metadata: %{},
      is_admin: true,
      originator: %Seeder{}
    },
    %{
      email: "viewer_branch1@example.com",
      password: generate_base64_key(16),
      metadata: %{},
      is_admin: true,
      originator: %Seeder{}
    }
  ]

  def seed do
    [
      run_banner: "Seeding sample admin panel users:",
      argsline: [],
    ]
  end

  def run(writer, _args) do
    Enum.each @seed_data, fn data ->
      run_with(writer, data)
    end
  end

  defp run_with(writer, data) do
    case User.get_by_email(data.email) do
      nil ->
        case User.insert(data) do
          {:ok, user} ->
            writer.success("""
              ID       : #{user.id}
              Email    : #{user.email}
              Password : #{data.password}
            """)
          {:error, changeset} ->
            writer.error("  Admin Panel user #{data.email} could not be inserted:")
            writer.print_errors(changeset)
          _ ->
            writer.error("  Admin Panel user #{data.email} could not be inserted:")
            writer.error("  Unknown error.")
        end
      %User{} = user ->
        writer.warn("""
          ID       : #{user.id}
          Email    : #{user.email}
          Password : <hidden>
        """)
    end
  end
end
