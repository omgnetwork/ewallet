defmodule LocalLedgerDB.Repo.Migrations.SwapNameBetweenEntryAndTransaction do
  use Ecto.Migration

  def up do
    # Rename tables (since it is name swapping, up and down can be the same)
    rename table(:entry), to: table(:transaction_new)
    rename table(:transaction), to: table(:entry)
    rename table(:transaction_new), to: table(:transaction)

    # Rename columns
    rename table(:entry), :entry_uuid, to: :transaction_uuid

    # Add new indices
    create unique_index(:transaction, [:idempotency_token])
    create index(:transaction, [:metadata], using: "gin")
    create index(:transaction, [:encryption_version])

    # Remove old indices after the new ones are added
    drop index(:transaction, [:idempotency_token], name: :entry_idempotency_token_index)
    drop index(:transaction, [:metadata], name: :entry_metadata_index)
    drop index(:transaction, [:encryption_version], name: :entry_encryption_version_index)

    # Add new constraints
    alter table(:entry) do
      modify :transaction_uuid, references(:transaction, type: :uuid, column: :uuid), null: false
      modify :wallet_address, references(:wallet, type: :string, column: :address), null: false
      modify :token_id, references(:token, type: :string, column: :id), null: false
    end

    # Remove old constraints after the new ones are added
    drop constraint(:entry, "transaction_entry_uuid_fkey")
    drop constraint(:entry, "transaction_wallet_address_fkey")
    drop constraint(:entry, "transaction_token_id_fkey")
  end

  def down do
    # Rename tables (since it is name swapping, up and down can be the same)
    rename table(:entry), to: table(:transaction_new)
    rename table(:transaction), to: table(:entry)
    rename table(:transaction_new), to: table(:transaction)

    # Rename columns
    rename table(:transaction), :transaction_uuid, to: :entry_uuid

    # Add new indices
    create unique_index(:entry, [:idempotency_token])
    create index(:entry, [:metadata], using: "gin")
    create index(:entry, [:encryption_version])

    # Remove old indices after the new ones are added
    drop index(:entry, [:idempotency_token], name: :transaction_idempotency_token_index)
    drop index(:entry, [:metadata], name: :transaction_metadata_index)
    drop index(:entry, [:encryption_version], name: :transaction_encryption_version_index)

    # Add new constraints
    alter table(:transaction) do
      modify :entry_uuid, references(:entry, type: :uuid, column: :uuid), null: false
      modify :wallet_address, references(:wallet, type: :string, column: :address), null: false
      modify :token_id, references(:token, type: :string, column: :id), null: false
    end

    # Remove old constraints after the new ones are added
    drop constraint(:transaction, "entry_transaction_uuid_fkey")
    drop constraint(:transaction, "entry_wallet_address_fkey")
    drop constraint(:transaction, "entry_token_id_fkey")
  end
end
