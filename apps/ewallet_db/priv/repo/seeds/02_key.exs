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

defmodule EWalletDB.Repo.Seeds.KeySeed do
  alias EWalletDB.Key
  alias EWalletDB.Seeder

  def seed do
    [
      run_banner: "Seeding the initial access and secret key:",
      argsline: []
    ]
  end

  def run(writer, args) do
    case Key.insert(%{originator: %Seeder{}}) do
      {:ok, key} ->
        writer.success("""
          Access key   : #{key.access_key}
          Secret key   : #{key.secret_key}
        """)

        args ++
          [
            {:seeded_ewallet_key_access, key.access_key},
            {:seeded_ewallet_key_secret, key.secret_key}
          ]

      {:error, changeset} ->
        writer.error("  Access/Secret for could not be inserted:")
        writer.print_errors(changeset)

      _ ->
        writer.error("  Access/Secret for could not be inserted:")
        writer.error("  Unknown error.")
    end
  end
end
