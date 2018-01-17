defmodule EWalletDB.Repo.Migrations.CreateRoleTable do
  use Ecto.Migration

  def change do
    create table(:role, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :display_name, :string

      timestamps()
    end

    create unique_index(:role, [:name])
  end
end
