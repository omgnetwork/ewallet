defmodule ExternalLedger.Repo.Migrations.CreateWalletTable do
  use Ecto.Migration

  def change do
    create table(:wallet, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :address, :string, null: false
      add :adapter, :string, null: false
      add :type, :string, null: false
      add :public_key, :string
      add :encrypted_private_key, :string
      add :metadata, :map, null: false, default: "{}"
      add :encrypted_metadata, :binary
      timestamps()
    end

    create unique_index(:wallet, [:address])
    create index(:wallet, [:type])
    create index(:wallet, [:adapter])
    create index(:wallet, [:metadata], using: "gin")
  end
end
