defmodule EWalletDB.Repo.Migrations.AddMaxConsumptionsPerIntervalAndConsumptionIntervalPerUser do
  use Ecto.Migration

  def change do
    alter table(:transaction_request) do
      add :max_consumptions_per_interval, :integer
      add :max_consumptions_per_interval_per_user, :integer
      add :consumption_interval_duration, :integer # milliseconds
    end
  end
end
