defmodule EWalletDB.Repo.Migrations.AddBlockchainFields1ToToken do
  use Ecto.Migration

  def change do
    alter table(:token) do
      add :tx_hash, :string
      add :blk_number, :integer
      add :contract_uuid, :string
    end

    create unique_index(:token, [:blockchain_identifier, :tx_hash])
    create index(:token, [:blockchain_identifier, :blk_number])
  end
end
