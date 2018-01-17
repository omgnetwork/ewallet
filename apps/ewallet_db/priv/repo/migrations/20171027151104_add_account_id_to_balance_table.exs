defmodule EWalletDB.Repo.Migrations.AddAccountIdToBalanceTable do
  use Ecto.Migration

  def change do
    alter table(:balance) do
      add :account_id, references(:account, type: :uuid)
    end
  end
end
