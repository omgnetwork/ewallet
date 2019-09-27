defmodule EWalletDB.Repo.Migrations.CreateBlockchainTransactionTable do
  use Ecto.Migration

  def up do
    create table(:blockchain_transaction, primary_key: false) do
      add :uuid, :uuid, null: false, primary_key: true
      add :hash, :string, null: false
      add :rootchain_identifier, :string, null: false
      add :childchain_identifier, :string
      add :status, :string, null: false
      add :block_number, :integer
      add :confirmed_at_block_number, :integer
      add :gas_price, :decimal, precision: 36, scale: 0
      add :gas_limit, :decimal, precision: 36, scale: 0
      add :error, :text
      add :metadata, :map, null: false

      timestamps()
    end

    create unique_index(:blockchain_transaction, [:hash])

    alter table(:transaction) do
      add(:blockchain_transaction_uuid, references(:blockchain_transaction, type: :uuid, column: :uuid))

      remove :blk_number
      remove :blockchain_metadata
      remove :confirmations_count
      remove :blockchain_identifier
      remove :blockchain_tx_hash
    end

    alter table(:token) do
      add(:blockchain_transaction_uuid, references(:blockchain_transaction, type: :uuid, column: :uuid))

      remove :tx_hash
      remove :blk_number
    end
  end

  def down do
    drop constraint(:transaction, "transaction_blockchain_transaction_uuid_fkey")
    drop constraint(:token, "token_blockchain_transaction_uuid_fkey")

    drop table(:blockchain_transaction)

    alter table(:transaction) do
      remove :blockchain_transaction_uuid

      add :blk_number, :integer
      add :blockchain_metadata, :map
      add :confirmations_count, :integer
      add :blockchain_identifier, :string
      add :blockchain_tx_hash, :string
    end

    alter table(:token) do
      remove :blockchain_transaction_uuid

      add :tx_hash, :string
      add :blk_number, :integer
    end
  end
end
