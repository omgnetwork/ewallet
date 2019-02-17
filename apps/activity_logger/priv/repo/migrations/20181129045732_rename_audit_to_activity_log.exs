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

defmodule ActivityLogger.Repo.Migrations.RenameAuditToActivityLogger do
  use Ecto.Migration

  def up do
    rename table(:audit), to: table(:activity_log)
    rename_constraint(:activity_log, "audit_pkey", "activity_log_pkey")
    create_index(:activity_log)
    create unique_index(:activity_log, [:id])
    drop_index(:audit)
  end

  def down do
    rename table(:activity_log), to: table(:audit)
    rename_constraint(:audit, "activity_log_pkey", "audit_pkey")
    create_index(:audit)
    drop_index(:activity_log)
    drop unique_index(:activity_log, [:id])
  end

  defp drop_index(table) do
    drop index(table, [:target_uuid, :target_type])
    drop index(table, [:originator_uuid, :originator_type])
  end

  defp create_index(table) do
    create index(table, [:target_uuid, :target_type])
    create index(table, [:originator_uuid, :originator_type])
  end

  defp rename_constraint(table, from_constraint, to_constraint) do
    execute ~s/ALTER TABLE "#{table}" RENAME CONSTRAINT "#{from_constraint}" TO "#{to_constraint}"/
  end
end
