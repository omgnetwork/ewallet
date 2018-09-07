defmodule EWalletDB.Repo.Migrations.AddAudit do
  use Ecto.Migration

  def change do
    create table(:audit, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :id, :string, null: false

      add :action, :string, null: false

      add :target_uuid, :uuid, null: false
      add :target_schema, :string, null: false
      add :target_changes, :map, null: false

      add :originator_uuid, :uuid
      add :originator_schema, :string

      add :metadata, :map

      add :inserted_at, :naive_datetime, default: fragment("now()")
    end

    create index(:audit, [:target_uuid, :target_schema])
    create index(:audit, [:originator_uuid, :originator_schema])
  end
end
