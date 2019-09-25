defmodule EWalletDB.Repo.Migrations.CreateBlockchainDepositWalletCachedBalance do
  use Ecto.Migration

  def change do
    create table(:blockchain_deposit_wallet_cached_balance, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :blockchain_deposit_wallet_address, references(:blockchain_deposit_wallet,
                                                         type: :citext, column: :address)
      add :token_uuid, references(:token, type: :uuid, column: :uuid)
      add :amount, :decimal, precision: 36, scale: 0, null: false
      add :blockchain_identifier, :string, null: false

      timestamps()
    end

    create unique_index(:blockchain_deposit_wallet_cached_balance, [
      :blockchain_deposit_wallet_address,
      :blockchain_identifier, :token_uuid
    ])

    create index(:blockchain_deposit_wallet_cached_balance, [:blockchain_identifier, :amount])
  end
end
