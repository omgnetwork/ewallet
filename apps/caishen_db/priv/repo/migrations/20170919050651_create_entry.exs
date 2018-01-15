defmodule CaishenDB.Repo.Migrations.CreateEntry do
  use Ecto.Migration

  def change do
    create table(:entry, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :metadata, :binary
      add :encryption_version, :binary
      timestamps()
    end

    create index(:entry, [:encryption_version])
  end
end
