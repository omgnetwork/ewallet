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

defmodule EWalletDB.Repo.Seeds.MembershipSeed do
  alias EWallet.Web.Preloader
  alias EWalletDB.{Account, Membership, Role, User, Seeder}

  @seed_data %{
    admin_email: System.get_env("E2E_TEST_ADMIN_EMAIL") || "test_admin@example.com"
  }

  def seed do
    [
      run_banner: "Seeding the admin membership",
      argsline: []
    ]
  end

  def run(writer, _args) do
    admin_email = @seed_data[:admin_email]

    user = User.get_by_email(admin_email)
    account = Account.get_master_account()
    role = Role.get_by(name: "admin")

    case Membership.get_by_member_and_account(user, account) do
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
            writer.error("  Admin Panel user #{admin_email} could not be assigned:")
            writer.print_errors(changeset)

          _ ->
            writer.error("  Admin Panel user #{admin_email} could not be assigned:")
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
