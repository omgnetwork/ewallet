defmodule LocalLedgerDB.Repo.Migrations.AddCachedCoutToCachedBalance do
  use Ecto.Migration

  def change do
    alter table(:cached_balance) do
      add :cached_count, :integer, default: 1, null: false
    end
  end
end
