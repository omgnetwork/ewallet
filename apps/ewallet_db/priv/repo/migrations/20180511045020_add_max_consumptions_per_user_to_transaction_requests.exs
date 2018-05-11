defmodule EWalletDB.Repo.Migrations.AddMaxConsumptionsPerUserToTransactionRequests do
  use Ecto.Migration

  def change do
    alter table(:transaction_request) do
      add :max_consumptions_per_user, :integer
    end
  end
end
