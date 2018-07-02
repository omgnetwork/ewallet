defmodule EWalletDB.Repo.Migrations.AddExchangeWalletAddressToTransaction do
  use Ecto.Migration

  def change do
    alter table(:transaction) do
      add :exchange_wallet_address, references(:wallet, type: :string, column: :address)
    end
  end
end
