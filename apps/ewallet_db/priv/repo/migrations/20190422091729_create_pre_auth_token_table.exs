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

defmodule EWalletDB.Repo.Migrations.CreatePreAuthTokenTable do
  use Ecto.Migration

  def change do
    create table(:pre_auth_token, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :id, :string
      add :token, :string, null: false
      add :user_uuid, references(:user, type: :uuid, column: :uuid)
      add :owner_app, :string, null: false
      add :account_uuid, references(:account, type: :uuid, column: :uuid)
      add :expired, :boolean, null: false, default: false

      timestamps()
    end

    create index(:pre_auth_token, [:owner_app])
    create unique_index(:pre_auth_token, [:id])
    create unique_index(:pre_auth_token, [:token])
  end
end
