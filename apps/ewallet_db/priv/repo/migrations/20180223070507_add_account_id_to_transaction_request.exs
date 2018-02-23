defmodule EWalletDB.Repo.Migrations.AddAccountIDToTransactionRequest do
  use Ecto.Migration

  def up do
    alter table(:transaction_request) do
      add :account_id, references(:account, type: :uuid)
    end
  end

  def down do
    alter table(:transaction_request) do
      remove :account_id
    end
  end
end
