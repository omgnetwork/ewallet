defmodule CaishenDB.Repo.Migrations.CreateBalances do
  use Ecto.Migration

  def change do
    create table(:balance, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :address, :string, null: false
      add :metadata, :binary
      add :encryption_version, :binary
      timestamps()
    end

    create unique_index(:balance, [:address])
    create index(:balance, [:encryption_version])
  end
end
