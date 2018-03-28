defmodule EWalletDB.Repo.Migrations.AddMetadataToConsumptions do
  use Ecto.Migration

  def change do
    rename table(:transaction_request_consumption), to: table(:transaction_consumption)

    alter table(:transaction_consumption) do
      add :approved, :boolean, default: false
      add :finalized_at, :naive_datetime
      add :expiration_date, :naive_datetime
      add :expired_at, :naive_datetime
      add :metadata, :map
      add :encrypted_metadata, :binary
      add :encryption_version, :binary
    end

    create index(:transaction_consumption, [:metadata], using: "gin")
    create index(:transaction_consumption, [:encryption_version])
    create index(:transaction_consumption, [:expiration_date])
  end
end
