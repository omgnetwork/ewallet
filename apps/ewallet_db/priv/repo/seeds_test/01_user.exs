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

defmodule EWalletDB.Repo.Seeds.UserSeed do
  alias EWalletDB.{Account, AccountUser, User}
  # credo:disable-for-next-line Credo.Check.Readability.AliasOrder
  alias EWalletDB.Seeder

  @seed_data [
    %{
      email: System.get_env("E2E_TEST_ADMIN_EMAIL") || "test_admin@example.com",
      password: System.get_env("E2E_TEST_ADMIN_PASSWORD") || "password",
      metadata: %{},
      account_name: "master_account",
      is_admin: true,
      global_role: "super_admin",
      originator: %Seeder{}
    },
    %{
      email: System.get_env("E2E_TEST_ADMIN_1_EMAIL") || "test_admin_1@example.com",
      password: System.get_env("E2E_TEST_ADMIN_1_PASSWORD") || "password",
      metadata: %{},
      account_name: "master_account",
      is_admin: true,
      originator: %Seeder{}
    },
    %{
      email: System.get_env("E2E_TEST_USER_EMAIL") || "test_user@example.com",
      password: System.get_env("E2E_TEST_USER_PASSWORD") || "password",
      metadata: %{},
      account_name: "master_account",
      is_admin: false,
      originator: %Seeder{}
    },
  ]

  def seed do
    [
      run_banner: "Seeding the 2 test admins and the test user",
      argsline: [],
    ]
  end

  def run(writer, _args) do
    Enum.each @seed_data, fn data ->
      run_with(writer, data)
    end
  end

  def run_with(writer, data) do
    case User.get_by_email(data.email) do
      nil ->
        case User.insert(data) do
          {:ok, user} ->
            account = Account.get_by(name: data.account_name)
            {:ok, _} = AccountUser.link(account.uuid, user.uuid, %Seeder{})

            writer.success("""
              ID       : #{user.id}
              Email    : #{user.email}
              Password : <hidden>
            """)

          {:error, changeset} ->
            writer.error("  User #{data.email} could not be inserted:")
            writer.print_errors(changeset)

          _ ->
            writer.error("  User #{data.email} could not be inserted:")
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
