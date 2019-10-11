defmodule EWalletDB.Repo.Migrations.UpdateDepositTransaction do
  use Ecto.Migration

  def up do
    drop index(:deposit_transaction, [:blockchain_identifier, :blockchain_tx_hash])

    alter table(:deposit_transaction) do
      add(
        :blockchain_transaction_uuid,
        references(:blockchain_transaction, type: :uuid, column: :uuid)
        )

      remove :blockchain_tx_hash
      remove :blockchain_identifier
      remove :transaction_uuid
    end
    create unique_index(:deposit_transaction, :blockchain_transaction_uuid)
  end

  def down do
    drop constraint(:deposit_transaction, "deposit_transaction_blockchain_transaction_uuid_fkey")
    drop unique_index(:deposit_transaction, :blockchain_transaction_uuid)
    alter table(:deposit_transaction) do
      remove :blockchain_transaction_uuid

      add :transaction_uuid, references(:transaction, column: :uuid, type: :uuid)

      add :blockchain_tx_hash, :string
      add :blockchain_identifier, :string
    end
    create index(:deposit_transaction, [:blockchain_identifier, :blockchain_tx_hash])
  end
end
