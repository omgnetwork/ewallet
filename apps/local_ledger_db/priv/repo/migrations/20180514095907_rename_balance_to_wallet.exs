defmodule LocalLedgerDB.Repo.Migrations.RenameBalanceToWallet do
  use Ecto.Migration

  def change do
    rename table(:balance), to: table(:wallet)

    rename table(:cached_balance), :balance_address, to: :wallet_address
    drop constraint(:cached_balance, "cached_balance_balance_address_fkey")

    rename table(:transaction), :balance_address, to: :wallet_address
    drop constraint(:transaction, "transaction_balance_address_fkey")

    drop index(:balance, [:address])
    create unique_index(:wallet, [:address])

    alter table(:cached_balance) do
      modify :wallet_address, references(:wallet, type: :string,
                                          column: :address), null: false
    end

    alter table(:transaction) do
      modify :wallet_address, references(:wallet, type: :string,
                                          column: :address), null: false
    end
  end
end
