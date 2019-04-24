defmodule EWalletDB.Repo.Migrations.AddExchangeAddressAndAllowEndUserExchangesToExchangePair do
  use Ecto.Migration

  def change do
    alter table(:exchange_pair) do
      add :default_exchange_wallet_address, references(:wallet, type: :string, column: :address)
      add :allow_end_user_exchanges, :boolean, default: false, null: false
    end

    create index(:exchange_pair, :default_exchange_wallet_address)
  end
end
