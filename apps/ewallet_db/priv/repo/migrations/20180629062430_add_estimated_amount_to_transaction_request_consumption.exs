defmodule EWalletDB.Repo.Migrations.AddEstimatedAmountToTransactionRequestConsumption do
  use Ecto.Migration

  def change do
    alter table(:transaction_consumption) do
      add :exchange_pair_uuid, references(:exchange_pair, type: :uuid, column: :uuid)
      add :estimated_at, :naive_datetime
      add :estimated_rate, :float
      add :estimated_request_amount, :decimal, precision: 81, scale: 0
      add :estimated_consumption_amount, :decimal, precision: 81, scale: 0
    end
  end
end
