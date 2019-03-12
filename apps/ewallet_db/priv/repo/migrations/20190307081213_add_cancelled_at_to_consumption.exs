defmodule EWalletDB.Repo.Migrations.AddCancelledAtToConsumption do
  use Ecto.Migration

  def change do
    alter table(:transaction_consumption) do
      add :cancelled_at, :naive_datetime_usec
    end
  end
end
