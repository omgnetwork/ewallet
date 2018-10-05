defmodule EWalletDB.Repo.Migrations.AddConsumptionsCountToRequests do
  use Ecto.Migration

  def change do
    alter table(:transaction_request) do
      add :consumptions_count, :integer
    end
  end
end
