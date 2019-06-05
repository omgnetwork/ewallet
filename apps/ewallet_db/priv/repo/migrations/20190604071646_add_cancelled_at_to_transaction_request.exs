defmodule EWalletDB.Repo.Migrations.AddCancelledAtToTransactionRequest do
  use Ecto.Migration

  def change do
    alter table(:transaction_request) do
      add :cancelled_at, :naive_datetime
    end
  end
end
