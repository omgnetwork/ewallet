defmodule EWalletDB.Repo.Migrations.AddBlockchainWallet do
  use Ecto.Migration

  def change do
    create table(:blockchain_wallet, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :address, :string, null: false
      add :public_key, :string
      add :name, :string
      add :type, :string, null: false

      timestamps()
    end

    create unique_index(:blockchain_wallet, [:public_key])
    create unique_index(:blockchain_wallet, [:address])
    create unique_index(:blockchain_wallet, [:name])
    create index(:blockchain_wallet, [:type])
  end
end
