defmodule EWalletDB.Repo.Migrations.AddParentIDToAccount do
  use Ecto.Migration

  def up do
    alter table(:account) do
      add :parent_id, references(:account, column: :id, type: :uuid)
    end
  end

  def down do
    alter table(:account) do
      remove :parent_id
    end
  end
end
