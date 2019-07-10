defmodule EWalletDB.Repo.Migrations.AddBlockchainIdentifierToBlockchainWallet do
  use Ecto.Migration

  def change do
    alter table(:blockchain_wallet) do
      add :blockchain_identifier, :string
    end

    drop constraint(:transaction, "transaction_from_blockchain_address_fkey")

    drop unique_index(:blockchain_wallet, [:address])
    drop unique_index(:blockchain_wallet, [:public_key])

    create unique_index(:blockchain_wallet, [:blockchain_identifier, :address])
    create unique_index(:blockchain_wallet, [:blockchain_identifier, :public_key])
  end
end
