# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWalletDB.Repo.Migrations.AddExports do
  use Ecto.Migration

  def change do
    create table(:export, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :id, :string, null: false

      add :schema, :string, null: false
      add :status, :string, null: false
      add :format, :string, null: false
      add :completion, :float, default: 0, null: false
      add :url, :string
      add :filename, :string
      add :path, :string
      add :params, :map
      add :failure_reason, :string
      add :estimated_size, :float
      add :total_count, :integer
      add :adapter, :string
      add :pid, :string
      add :user_uuid, references(:user, column: :uuid, type: :uuid)
      add :key_uuid, references(:key, column: :uuid, type: :uuid)

      timestamps()
    end

    create unique_index(:export, [:id])
    create index(:export, [:user_uuid])
    create index(:export, [:key_uuid])
  end
end
