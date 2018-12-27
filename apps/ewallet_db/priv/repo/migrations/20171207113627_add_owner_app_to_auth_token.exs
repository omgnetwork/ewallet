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

defmodule EWalletDB.Repo.Migrations.AddOwnerAppToAuthTokenTable do
  use Ecto.Migration
  alias EWalletDB.Repo

  def up do
    # Add :owner_app without `null: false`, so existing records won't break migration.
    alter table(:auth_token) do
      add :owner_app, :string
    end
    create index(:auth_token, [:owner_app])
    flush()

    # We don't know for sure which app those tokens belong to before this migration,
    # so it's better to assign all existing tokens as :invalid_app
    Repo.update_all("auth_token", set: [owner_app: "invalid_app"])

    # Finally make :owner_app column not-nullable
    alter table(:auth_token) do
      modify :owner_app, :string, null: false
    end
  end

  def down do
    # We'll lose the scope of the token after dropping :auth_token column.
    # Definitely not wanting a token from a specific app to be usable everywhere else.
    Repo.update_all("auth_token", set: [expired: true])

    drop index(:auth_token, [:owner_app])
    alter table(:auth_token) do
      remove :owner_app
    end
  end
end
