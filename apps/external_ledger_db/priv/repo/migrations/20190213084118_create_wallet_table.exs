defmodule ExternalLedgerDB.Repo.Migrations.CreateWalletTable do
  use Ecto.Migration

  def change do
    create table(:wallet, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :address, :string, null: false
      add :adapter, :string, null: false
      add :type, :string, null: false
      add :primary, :boolean, default: false
      add :public_key, :string, null: false
      add :metadata, :map, null: false, default: "{}"
      add :encrypted_metadata, :binary
      timestamps()
    end

    create unique_index(:wallet, [:address])
    create index(:wallet, [:adapter])
    create index(:wallet, [:type])
    create index(:wallet, [:primary])
    create index(:wallet, [:public_key])
    create index(:wallet, [:metadata], using: "gin")
  end
end
