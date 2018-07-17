defmodule EWalletDB.Repo.Migrations.FixExchangeAccountInConsumption do
  use Ecto.Migration

  def change do
    alter table(:transaction_consumption) do
      remove :exchange_account_uuid
    end

    flush()

    alter table(:transaction_consumption) do
      add :exchange_account_uuid, references(:account, type: :uuid, column: :uuid)
    end
  end
end
