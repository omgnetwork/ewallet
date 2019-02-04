defmodule EWalletDB.Repo.Migrations.DropPriorityFromRole do
  use Ecto.Migration

  def up do
    alter table(:role) do
      remove :priority
    end
  end

  def down do
    alter table(:role) do
      add :priority, :integer
    end

    create unique_index(:role, [:priority])
  end
end
