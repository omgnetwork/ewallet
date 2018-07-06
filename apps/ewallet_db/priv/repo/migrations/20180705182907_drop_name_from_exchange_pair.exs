defmodule EWalletDB.Repo.Migrations.DropNameFromExchangePair do
  use Ecto.Migration

  def up do
    alter table(:exchange_pair) do
      remove :name
    end
  end

  def down do
    alter table(:exchange_pair) do
      add :name, :string, null: false
    end
  end
end
