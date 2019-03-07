defmodule EWalletDB.Repo.Migrations.CleanupHierarchy do
  use Ecto.Migration

  def up do
    alter table(:account) do
      remove :parent_uuid
    end
  end

  def down do
    alter table(:account) do
      add :parent_uuid, references(:account, column: :uuid, type: :uuid)
    end
  end
end
