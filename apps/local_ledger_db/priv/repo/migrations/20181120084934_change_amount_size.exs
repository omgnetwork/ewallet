defmodule LocalLedgerDB.Repo.Migrations.ChangeAmountSize do
  use Ecto.Migration

  def up do
    alter table(:entry) do
      modify :amount, :decimal, precision: nil, scale: 0, null: false
    end
  end

  def down do
    alter table(:entry) do
      modify :amount, :decimal, precision: 81, scale: 0, null: false
    end
  end
end
