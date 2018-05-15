defmodule LocalLedgerDB.Repo.Migrations.RenameBalanceToWallet do
  use Ecto.Migration

  def change do
    rename table(:balance), to: table(:wallet)
  end
end
