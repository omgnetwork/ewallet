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

defmodule EWalletDB.Repo.Seeds.MembershipSampleSeed do
  alias EWallet.Web.Preloader
  alias EWalletDB.{Account, Membership, Role, User}
  alias EWalletDB.Seeder

  @seed_data [
    %{email: "admin_brand1@example.com", role_name: "admin", account_name: "brand1"},
    %{email: "admin_branch1@example.com", role_name: "admin", account_name: "branch1"},
    %{email: "viewer_master@example.com", role_name: "viewer", account_name: "master_account"},
    %{email: "viewer_brand1@example.com", role_name: "viewer", account_name: "brand1"},
    %{email: "viewer_branch1@example.com", role_name: "viewer", account_name: "branch1"}
  ]

  def seed do
    [
      run_banner: "Seeding sample admin memberships:",
      argsline: []
    ]
  end

  def run(writer, _args) do
    Enum.each(@seed_data, fn data ->
      run_with(writer, data)
    end)
  end

  defp run_with(writer, data) do
    account = Account.get_by(name: data.account_name)
    user = User.get_by(email: data.email)
    role = Role.get_by(name: data.role_name)

    case Membership.get_by_user_and_account(user, account) do
      nil ->
        case Membership.assign(user, account, role, %Seeder{}) do
          {:ok, membership} ->
            {:ok, membership} = Preloader.preload_one(membership, [:user, :account, :role])

            writer.success("""
              Email        : #{membership.user.email}
              Account Name : #{membership.account.name}
              Account ID   : #{membership.account.id}
              Role         : #{membership.role.name}
            """)

          {:error, changeset} ->
            writer.error("  Admin Panel user #{data.email} could not be assigned:")
            writer.print_errors(changeset)

          _ ->
            writer.error("  Admin Panel user #{data.email} could not be assigned:")
            writer.error("  Unknown error.")
        end

      %Membership{} = membership ->
        {:ok, membership} = Preloader.preload_one(membership, [:user, :account, :role])

        writer.warn("""
          Email        : #{membership.user.email}
          Account Name : #{membership.account.name}
          Account ID   : #{membership.account.id}
          Role         : #{membership.role.name}
        """)
    end
  end
end
