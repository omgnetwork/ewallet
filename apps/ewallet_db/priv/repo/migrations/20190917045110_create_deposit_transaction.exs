defmodule EWalletDB.Repo.Migrations.AddDepositTransaction do
  use Ecto.Migration

  def change do
    create unique_index(:blockchain_wallet, [:address])

    create table(:deposit_transaction, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :id, :string, null: false
      add :type, :string, null: false
      add :blockchain_tx_hash, :string
      add :blockchain_identifier, :string
      add :amount, :decimal, precision: 36, scale: 0, null: false

      add :token_uuid, references(:token, column: :uuid, type: :uuid), null: false

      add :transaction_uuid, references(:transaction, column: :uuid, type: :uuid)

      add :from_blockchain_wallet_address, references(:blockchain_wallet,
                                                      type: :citext, column: :address)

      add :to_blockchain_wallet_address, references(:blockchain_wallet,
                                                    type: :citext, column: :address)

      add :from_deposit_wallet_address, references(:blockchain_deposit_wallet,
                                                   type: :citext, column: :address)

      add :to_deposit_wallet_address, references(:blockchain_deposit_wallet,
                                                 type: :citext, column: :address)

      timestamps()
    end

    create index(:deposit_transaction, [:id])
    create index(:deposit_transaction, [:blockchain_identifier, :blockchain_tx_hash])
  end
end
