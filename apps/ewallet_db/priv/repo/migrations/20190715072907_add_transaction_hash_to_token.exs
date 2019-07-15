defmodule EWalletDB.Repo.Migrations.AddTransactionHashToToken do
  use Ecto.Migration

  def change do
    alter table(:token) do
      add :tx_hash, :string
    end

    create unique_index(:token, [:blockchain_identifier, :tx_hash])
  end
end
