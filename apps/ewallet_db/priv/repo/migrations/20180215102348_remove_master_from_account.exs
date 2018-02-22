defmodule EWalletDB.Repo.Migrations.RemoveMasterFromAccount do
  use Ecto.Migration

  def up do
    alter table(:account) do
      remove :master
    end
  end

  def down do
    alter table(:account) do
      add :master, :boolean, default: false, null: false
    end
  end
end
