defmodule EWalletDB.Repo.Migrations.AddDeletedAtToApiKeyTable do
  use Ecto.Migration

  def change do
    alter table(:api_key) do
      add :deleted_at, :naive_datetime
    end

    create index(:api_key, [:deleted_at])
  end
end
