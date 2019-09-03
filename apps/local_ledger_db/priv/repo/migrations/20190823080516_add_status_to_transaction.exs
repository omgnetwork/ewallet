defmodule LocalLedgerDB.Repo.Migrations.AddStatusToTransaction do
  use Ecto.Migration

  def change do
    alter table(:transaction) do
      add :status, :string, null: false, default: "confirmed"
    end

    alter table(:entry) do
      add :status, :string, null: false, default: "confirmed"
    end

    create index(:transaction, :status)
    create index(:entry, :status)
  end
end
