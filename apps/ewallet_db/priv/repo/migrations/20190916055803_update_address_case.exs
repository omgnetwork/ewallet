defmodule EWalletDB.Repo.Migrations.UpdateAddressCase do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS citext"
    alter table(:blockchain_wallet) do
      modify :address, :citext
    end

    alter table(:transaction) do
      modify :from_blockchain_address, :citext
      modify :to_blockchain_address, :citext
    end

    alter table(:token) do
      modify :blockchain_address, :citext
    end

    alter table(:blockchain_deposit_wallet) do
      modify :address, :citext
      modify :wallet_address, :citext
    end
  end

  def down do
    alter table(:blockchain_wallet) do
      modify :address, :string
    end

    alter table(:transaction) do
      modify :from_blockchain_address, :string
      modify :to_blockchain_address, :string
    end

    alter table(:token) do
      modify :blockchain_address, :string
    end

    alter table(:blockchain_deposit_wallet) do
      modify :address, :string
      modify :wallet_address, :string
    end
    execute "DROP EXTENSION IF EXISTS citext"
  end
end
