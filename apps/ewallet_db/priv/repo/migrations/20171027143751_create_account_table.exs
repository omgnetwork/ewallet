defmodule EWalletDB.Repo.Migrations.CreateAccountTable do
  use Ecto.Migration

  def change do
    create table(:account, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :description, :string
      add :master, :boolean, default: false, null: false

      timestamps()
    end

    create unique_index(:account, [:name])
  end
end
