defmodule EWalletDB.Repo.Migrations.AddDeletedAtToKeyTable do
  use Ecto.Migration

  def change do
    alter table(:key) do
      add :deleted_at, :naive_datetime
    end

    create index(:key, [:deleted_at])
  end
end
