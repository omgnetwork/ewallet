defmodule EWalletDB.Repo.Migrations.CreateBlockchainDepositWallet do
  use Ecto.Migration

  def change do
    create table(:blockchain_deposit_wallet, primary_key: false) do
      add(:uuid, :uuid, primary_key: true)
      add(:address, :string, null: false)
      add(:blockchain_hd_wallet_uuid, references(:blockchain_hd_wallet, type: :uuid, column: :uuid))
      add(:wallet_uuid, references(:wallet, type: :uuid, column: :uuid))
      add(:relative_hd_path, :integer)
      add(:blockchain_identifier, :string, null: false)

      timestamps()
    end

    create unique_index(:blockchain_deposit_wallet, [:address])
    create unique_index(:blockchain_deposit_wallet, [:wallet_uuid, :relative_hd_path])

    create index(:blockchain_deposit_wallet, [:blockchain_identifier])
  end
end
