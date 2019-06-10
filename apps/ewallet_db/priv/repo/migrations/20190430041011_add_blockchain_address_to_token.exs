defmodule EWalletDB.Repo.Migrations.AddBlockchainAddressToToken do
  use Ecto.Migration

  def change do
    alter table(:token) do
      add :blockchain_address, :string
    end
    create unique_index(:token, [:blockchain_address])
  end
end
