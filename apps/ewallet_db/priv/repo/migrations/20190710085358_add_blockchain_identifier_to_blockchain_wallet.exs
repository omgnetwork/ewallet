defmodule EWalletDB.Repo.Migrations.AddBlockchainIdentifierToBlockchainWallet do
  use Ecto.Migration
  alias EWalletDB.Repo

  def up do
    alter table(:blockchain_wallet) do
      add :blockchain_identifier, :string
    end

    flush()

    {:ok, _} = Repo.query("UPDATE blockchain_wallet SET blockchain_identifier = 'ethereum' WHERE blockchain_identifier IS NULL")

    drop constraint(:transaction, "transaction_from_blockchain_address_fkey")

    drop unique_index(:blockchain_wallet, [:address])
    drop unique_index(:blockchain_wallet, [:public_key])

    create unique_index(:blockchain_wallet, [:blockchain_identifier, :address])
    create unique_index(:blockchain_wallet, [:blockchain_identifier, :public_key])
  end

  def down do
    alter table(:blockchain_wallet) do
      remove :blockchain_identifier
    end

    create unique_index(:blockchain_wallet, [:address])
    create unique_index(:blockchain_wallet, [:public_key])

    alter table(:transaction) do
      modify :from_blockchain_address, references(:blockchain_wallet, type: :string, column: :address)
    end
  end
end
