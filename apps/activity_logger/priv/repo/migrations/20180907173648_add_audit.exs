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

defmodule ActivityLogger.Repo.Migrations.AddAudit do
  use Ecto.Migration

  def change do
    create table(:audit, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :id, :string, null: false

      add :action, :string, null: false

      add :target_uuid, :uuid, null: false
      add :target_type, :string, null: false
      add :target_changes, :map, null: false
      add :target_encrypted_metadata, :binary

      add :originator_uuid, :uuid
      add :originator_type, :string

      add :metadata, :map

      add :inserted_at, :naive_datetime_usec
    end

    create index(:audit, [:target_uuid, :target_type])
    create index(:audit, [:originator_uuid, :originator_type])
  end
end
