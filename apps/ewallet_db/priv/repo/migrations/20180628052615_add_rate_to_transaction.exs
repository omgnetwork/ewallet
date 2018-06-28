defmodule EWalletDB.Repo.Migrations.AddRateToTransaction do
  use Ecto.Migration

  def change do
    alter table(:transaction) do
      add :rate, :float
      add :calculated_at, :naive_datetime
      add :exchange_pair_uuid, references(:exchange_pair, type: :uuid, column: :uuid)
    end
  end
end
