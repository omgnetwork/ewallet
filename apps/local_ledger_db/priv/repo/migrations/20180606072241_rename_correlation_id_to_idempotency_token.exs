defmodule LocalLedgerDB.Repo.Migrations.RenameCorrelationIDToIdempotencyToken do
  use Ecto.Migration

  def change do
    drop index(:entry, [:correlation_id])
    rename table(:entry), :correlation_id, to: :idempotency_token
    create unique_index(:entry, [:idempotency_token])
  end
end
