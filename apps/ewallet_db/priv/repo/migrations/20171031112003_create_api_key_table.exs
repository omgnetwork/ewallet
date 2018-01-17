defmodule EWalletDB.Repo.Migrations.CreateAPIKeyTable do
  use Ecto.Migration

  def change do
    create table(:api_key, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :key, :string, null: false
      add :account_id, references(:account, type: :uuid)
      add :expired, :boolean, null: false, default: false

      timestamps()
    end

    create unique_index(:api_key, [:key])
  end
end
