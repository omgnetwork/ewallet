defmodule EWalletDB.Repo.Migrations.RenameUnicityConstraintForConsumptionCorrelationID do
  use Ecto.Migration

  def change do
    drop index(:transaction_consumption, [:correlation_id],
               name: :transaction_request_consumption_correlation_id_index)
    create unique_index(:transaction_consumption, [:correlation_id])
  end
end
