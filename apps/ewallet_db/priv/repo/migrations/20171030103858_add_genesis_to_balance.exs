defmodule EWalletDB.Repo.Migrations.AddGenesisToBalance do
  use Ecto.Migration

  def change do
    alter table(:balance) do
      add :genesis, :boolean, default: false, null: false
    end
  end
end
