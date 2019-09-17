defmodule EWalletDB.Repo.Migrations.AddDepositTransaction do
  use Ecto.Migration

  def change do
    create unique_index(:blockchain_wallet, [:address])

    create table(:deposit_transaction, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :id, :string, null: false
      add :status, :string, default: "pending", null: false
      add :type, :string, null: false
      add :from_blockchain_wallet_address, references(:blockchain_wallet, type: :citext, column: :address)
      add :to_blockchain_wallet_address, references(:blockchain_wallet, type: :citext, column: :address)
      add :from_deposit_wallet_address, references(:blockchain_deposit_wallet, type: :citext, column: :address)
      add :to_deposit_wallet_address, references(:blockchain_deposit_wallet, type: :citext, column: :address)
      add :token_uuid, references(:token, column: :uuid, type: :uuid), null: true
      add :amount, :decimal, precision: 36,
                                  scale: 0,
                                  null: true
      add :gas_price, :decimal, precision: 36,
                                  scale: 0,
                                  null: true
      add :gas_limit, :decimal, precision: 36,
                                  scale: 0,
                                  null: true
      add :blockchain_tx_hash, :string
      add :blockchain_identifier, :string
      add :confirmations_count, :integer
      add :blk_number, :integer

      add :error_code, :string
      add :error_description, :string
      add :error_data, :map


      timestamps()
    end

    create index(:deposit_transaction, [:blockchain_identifier, :blk_number])
    create index(:deposit_transaction, [:from_blockchain_wallet_address])
    create index(:deposit_transaction, [:from_deposit_wallet_address])
    create index(:deposit_transaction, [:to_blockchain_wallet_address])
    create index(:deposit_transaction, [:to_deposit_wallet_address])
    create index(:deposit_transaction, [:token_uuid])
    create index(:deposit_transaction, [:id])
    create unique_index(:deposit_transaction, [:blockchain_tx_hash, :blockchain_identifier], name: :unique_hash_constraint)
  end
end

