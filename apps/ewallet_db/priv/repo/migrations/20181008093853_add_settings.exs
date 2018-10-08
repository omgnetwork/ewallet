defmodule EWalletDB.Repo.Migrations.AddSettings do
  use Ecto.Migration

  def change do
    create table(:setting, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :id, :string, null: false

      add :key, :string, null: false
      add :value, :string

      timestamps()
    end

    create unique_index(:setting, [:key])
  end
end
