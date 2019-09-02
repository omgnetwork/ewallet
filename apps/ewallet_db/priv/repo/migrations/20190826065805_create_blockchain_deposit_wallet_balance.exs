defmodule EWalletDB.Repo.Migrations.CreateBlockchainDepositWalletBalance do
  use Ecto.Migration

  def change do
    create table(:blockchain_deposit_wallet_balance, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :blockchain_deposit_wallet_address, references(:blockchain_deposit_wallet, type: :string, column: :address)
      add :token_uuid, references(:token, type: :uuid, column: :uuid)
      # We're not doing calculations on this, it's only used to find deposit wallet
      # for which we need to move funds from
      add :amount, :decimal, precision: 36, scale: 0, null: false
      add :blockchain_identifier, :string, null: false

      timestamps()
    end

    create unique_index(:blockchain_deposit_wallet_balance, [:blockchain_deposit_wallet_address, :blockchain_identifier, :token_uuid])
    create index(:blockchain_deposit_wallet_balance, [:blockchain_identifier, :amount])
  end
end
