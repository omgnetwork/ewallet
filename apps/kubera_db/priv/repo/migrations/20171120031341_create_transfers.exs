defmodule KuberaDB.Repo.Migrations.CreateTransfers do
  use Ecto.Migration

  def change do
    create table(:transfer, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :idempotency_token, :string, null: false
      add :status, :string, default: "pending", null: false
      add :type, :string, default: "internal", null: false
      add :payload, :binary, null: false
      add :ledger_response, :binary
      add :metadata, :binary
      add :encryption_version, :binary
      timestamps()
    end

    create unique_index(:transfer, [:idempotency_token])
  end
end
