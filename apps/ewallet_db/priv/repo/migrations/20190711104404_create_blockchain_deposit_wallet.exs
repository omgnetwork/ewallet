defmodule EWalletDB.Repo.Migrations.CreateBlockchainDepositWallet do
  use Ecto.Migration

  def change do
    create table(:blockchain_deposit_wallet, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :address, :string, null: false
      add :public_key, :string
      add(:wallet_address, references(:wallet, type: :string, column: :address))

      timestamps()
    end

    create unique_index(:blockchain_deposit_wallet, [:public_key])
    create unique_index(:blockchain_deposit_wallet, [:address])
  end
end
