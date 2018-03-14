defmodule EWalletDB.Repo.Migrations.AddMetadataToConsumptions do
  use Ecto.Migration

  def change do
    alter table(:transaction_request_consumption) do
      add :approved, :boolean, default: false
      add :finalized_at, :naive_datetime
      add :expires_at, :naive_datetime
      add :metadata, :map
      add :encrypted_metadata, :binary
      add :encryption_version, :binary
    end

    create index(:transaction_request_consumption, [:metadata], using: "gin")
    create index(:transaction_request_consumption, [:encryption_version])
  end
end
