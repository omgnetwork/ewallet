defmodule EWalletDB.Repo.Migrations.AddBlockchainFieldsToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transaction) do
      add :from_blockchain_address, references(:blockchain_wallet, type: :string, column: :address)
      add :to_blockchain_address, :string
      add :blockchain_tx_hash, :string
      add :blockchain_identifier, :string
      add :confirmations_count, :integer
      add :blockchain_metadata, :map
    end

    execute("ALTER TABLE transaction ALTER \"to\" DROP NOT NULL, ALTER \"from\" DROP NOT NULL;")
  end
end
