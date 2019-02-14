defmodule ExternalLedgerDB.Repo.Migrations.CreateTokenTable do
  use Ecto.Migration

  def change do
    create table(:token, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :id, :string, null: false
      add :adapter, :string, null: false
      add :contract_address, :string, null: false
      add :metadata, :map, null: false, default: "{}"
      add :encrypted_metadata, :binary
      timestamps()
    end

    create unique_index(:token, [:id])
    create index(:token, [:adapter])
    create index(:token, [:contract_address])
    create index(:token, [:metadata], using: "gin")
  end
end
