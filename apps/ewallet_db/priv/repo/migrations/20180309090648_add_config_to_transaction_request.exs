defmodule EWalletDB.Repo.Migrations.AddConfigToTransactionRequest do
  use Ecto.Migration

  def change do
    alter table(:transaction_request) do
      add :require_confirmation, :boolean, null: false, default: false
      add :max_consumptions, :integer
      add :consumption_lifetime, :integer # milliseconds
      add :expiration_date, :naive_datetime
      add :expired_at, :naive_datetime
      add :expiration_reason, :string
      add :allow_amount_override, :boolean, default: true
      add :metadata, :map
      add :encrypted_metadata, :binary
      add :encryption_version, :binary
    end

    create index(:transaction_request, [:metadata], using: "gin")
    create index(:transaction_request, [:encryption_version])
    create index(:transaction_request, [:expiration_date])
  end
end
