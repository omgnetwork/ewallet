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

defmodule EWalletDB.Repo.Seeds.MembershipSeed do
  alias EWallet.Web.Preloader
  alias EWalletDB.{Account, Membership, Role, Key, User}
  alias EWalletDB.Seeder

  def seed do
    [
      run_banner: "Seeding the admin membership",
      argsline: []
    ]
  end

  def run(writer, args) do
    admin_email = args[:admin_email]
    seeded_ewallet_key_access = args[:seeded_ewallet_key_access]

    user = User.get_by_email(admin_email)
    key = Key.get_by(access_key: seeded_ewallet_key_access)
    account = Account.get_master_account()
    role = Role.get_by(name: "admin")

    add_membership_for(user, account, role, writer)
    add_membership_for(key, account, role, writer)
  end

  def add_membership_for(actor, account, role, writer) do
    case Membership.get_by_member_and_account(actor, account) do
      nil ->
        case Membership.assign(actor, account, role, %Seeder{}) do
          {:ok, membership} ->
            {:ok, membership} = Preloader.preload_one(membership, [:user, :key, :account, :role])

            print_success(actor, membership, writer)

          {:error, changeset} ->
            print_error(actor, writer, changeset)

          _ ->
            print_error(actor, writer, "  Unknown error.")
        end

      %Membership{} = membership ->
        {:ok, membership} = Preloader.preload_one(membership, [:user, :key, :account, :role])

        print_success(actor, membership, writer)
    end
  end

  defp print_success(%User{}, membership, writer) do
    writer.success("""
      Email        : #{membership.user.email}
      Account Name : #{membership.account.name}
      Account ID   : #{membership.account.id}
      Role         : #{membership.role.name}
    """)
  end

  defp print_success(%Key{}, membership, writer) do
    writer.success("""
      Email        : #{membership.key.access_key}
      Account Name : #{membership.account.name}
      Account ID   : #{membership.account.id}
      Role         : #{membership.role.name}
    """)
  end

  def print_error(%User{} = user, writer, %{} = changeset) do
    writer.error("  Admin Panel user #{user.admin_email} could not be assigned:")
    writer.print_errors(changeset)
  end

  def print_error(%Key{} = key, writer, %{} = changeset) do
    writer.error("  Admin Panel user #{key.access_key} could not be assigned:")
    writer.print_errors(changeset)
  end

  def print_error(%User{} = user, writer, description) do
    writer.error("  Admin Panel user #{user.admin_email} could not be assigned:")
    writer.error(description)
  end

  def print_error(%Key{} = key, writer, description) do
    writer.error("  Admin Panel user #{key.access_key} could not be assigned:")
    writer.error(description)
  end
end
