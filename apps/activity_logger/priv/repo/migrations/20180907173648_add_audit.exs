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

      add :inserted_at, :naive_datetime
    end

    create index(:audit, [:target_uuid, :target_type])
    create index(:audit, [:originator_uuid, :originator_type])
  end
end
