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

defmodule EWalletDB.Repo.Migrations.CreateAccountUser do
  use Ecto.Migration

  def change do
    create table(:account_user, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :account_uuid, references(:account, type: :uuid, column: :uuid), null: false
      add :user_uuid, references(:user, type: :uuid, column: :uuid), null: false
      timestamps()
    end

    create unique_index(:account_user, [:account_uuid, :user_uuid])
    create index(:account_user, [:user_uuid])
  end
end
