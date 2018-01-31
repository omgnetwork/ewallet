defmodule LocalLedgerDB.Repo.Migrations.CreateCachedBalance do
  use Ecto.Migration

  def change do
    create table(:cached_balance, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :computed_at, :naive_datetime, null: false
      add :amounts, :map, null: false
      add :balance_address, references(:balance, type: :string,
                                                 column: :address), null: false
      timestamps()
    end
  end
end
