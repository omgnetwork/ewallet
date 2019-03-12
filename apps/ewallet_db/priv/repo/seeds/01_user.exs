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
  alias EWalletDB.{Account, User, GlobalRole}
  alias Utils.Helpers.Crypto
  alias EWalletDB.Seeder

  @argsline_desc """
  This email and password combination is required for logging into the admin panel.
  If a user with this email already exists, it will escalate the user to admin role,
  but the password will not be changed.
  """

  def seed do
    [
      run_banner: "Seeding the initial admin panel user",
      argsline: [
        {:title, "What email and password should I set for your first admin user?"},
        {:text, @argsline_desc},
        {:input, {:email, :admin_email, "E-mail", "admin@example.com"}},
        {:input, {:password, :admin_password, "Password", {Crypto, :generate_base64_key, [16]}}}
      ]
    ]
  end

  def run(writer, args) do
    data = %{
      email: args[:admin_email],
      password: args[:admin_password],
      metadata: %{},
      account_uuid: Account.get_master_account().uuid,
      is_admin: true,
      global_role: GlobalRole.super_admin(),
      originator: %Seeder{}
    }

    case User.get_by_email(data.email) do
      nil ->
        case User.insert(data) do
          {:ok, user} ->
            writer.success("""
              ID       : #{user.id}
              Email    : #{user.email}
              Password : #{user.password}
            """)

            args ++
              [
                {:seeded_admin_user_id, user.id},
                {:seeded_admin_user_email, user.email},
                {:seeded_admin_user_password, user.password}
              ]

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

        args ++
          [
            {:seeded_admin_user_id, user.id},
            {:seeded_admin_user_email, user.email},
            {:seeded_admin_user_password, "<hidden>"}
          ]
    end
  end
end
