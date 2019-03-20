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

defmodule EWalletDB.Repo.Seeds.APIKeySampleSeed do
  alias EWallet.Web.Preloader
  alias EWalletDB.{Account, APIKey}
  alias EWalletDB.Seeder

  def seed do
    [
      run_banner: "Seeding sample API keys:",
      argsline: []
    ]
  end

  def run(writer, args) do
    account = Account.get_by(name: "master_account")
    data = %{account_uuid: account.uuid, originator: %Seeder{}}

    case APIKey.insert(data) do
      {:ok, api_key} ->
        {:ok, api_key} = Preloader.preload_one(api_key, :account)

        writer.success("""
          Owner app       : #{api_key.owner_app}
          API key ID      : #{api_key.id}
          API key         : #{api_key.key}
        """)

        args ++ [{:seeded_ewallet_api_key, api_key.key}]

      {:error, changeset} ->
        writer.error("  API key could not be inserted:")
        writer.print_errors(changeset)

      _ ->
        writer.error("  API key could not be inserted:")
        writer.error("  Unknown error.")
    end
  end
end
