defmodule EWalletDB.Repo.Migrations.AddExchangeDetailsToTransactionRequestConsumption do
  use Ecto.Migration

  def change do
    alter table(:transaction_request) do
      add :exchange_account_uuid, references(:account, type: :uuid, column: :uuid)
      add :exchange_wallet_address, references(:wallet, type: :string, column: :address)
    end

    alter table(:transaction_consumption) do
      add :exchange_account_uuid, references(:wallet, type: :uuid, column: :uuid)
      add :exchange_wallet_address, references(:wallet, type: :string, column: :address)
    end
  end
end
