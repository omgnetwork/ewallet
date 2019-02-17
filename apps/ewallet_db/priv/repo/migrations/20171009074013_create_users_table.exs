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

defmodule EWalletDB.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create table(:user, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :username, :string, null: false
      add :provider_user_id, :string
      add :metadata, :map
      timestamps()
    end

    create unique_index(:user, [:username])
    create unique_index(:user, [:provider_user_id])
  end
end
