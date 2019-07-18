defmodule EWalletDB.Repo.Migrations.AddBlockchainFieldsToToken do
  use Ecto.Migration

  def change do
    alter table(:token) do
      add :blockchain_status, :string
      add :blockchain_identifier, :string
    end

    drop unique_index(:token, [:blockchain_address])
    create index(:token, [:blockchain_identifier, :blockchain_status])
    create unique_index(:token, [:blockchain_identifier, :blockchain_address])
  end
end
