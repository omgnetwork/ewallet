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
