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

defmodule EWalletDB.Repo.Seeds.AuthTokenSampleSeed do
  alias EWallet.Web.Preloader
  alias EWalletDB.{AuthToken, User, Seeder}

  def seed do
    [
      run_banner: "Seeding sample auth tokens:",
      argsline: []
    ]
  end

  def run(writer, args) do
    user = User.get_by_provider_user_id("provider_user_id01")

    case AuthToken.generate(user, :ewallet_api, %Seeder{}) do
      {:ok, token} ->
        {:ok, token} = Preloader.preload_one(token, :user)

        writer.success("""
          Owner app        : #{token.owner_app}
          User ID          : #{token.user.id}
          Provider user ID : #{token.user.provider_user_id || '<not set>'}
          User email       : #{token.user.email || '<not set>'}
          Auth token       : #{token.token}
        """)

        args ++
          [
            {:seeded_ewallet_user_id, user.id},
            {:seeded_ewallet_auth_token, token.token}
          ]

      {:error, changeset} ->
        writer.error("  Auth token for #{user.id} and ewallet_api could not be inserted:")
        writer.print_errors(changeset)

      _ ->
        writer.error("  Auth token for #{user.id} and ewallet_api could not be inserted:")
        writer.error("  Unknown error.")
    end
  end
end
