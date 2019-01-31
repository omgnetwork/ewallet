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

defmodule EWalletDB.Repo.Migrations.CreateCategoryTable do
  use Ecto.Migration

  def change do
    create table(:category, primary_key: false) do
      add :id, :string, null: false
      add :uuid, :uuid, primary_key: true
      add :name, :string, null: false
      add :description, :string
      timestamps()
      add :deleted_at, :naive_datetime_usec
    end

    create unique_index(:category, [:name])
    create index(:category, [:deleted_at])

    # Create the pivot table to support many-to-many account <-> category relationship
    create table(:account_category, primary_key: false) do
      add :account_uuid, references(:account, column: :uuid, type: :uuid)
      add :category_uuid, references(:category, column: :uuid, type: :uuid)
    end

    create unique_index(:account_category, [:account_uuid, :category_uuid])
  end
end
