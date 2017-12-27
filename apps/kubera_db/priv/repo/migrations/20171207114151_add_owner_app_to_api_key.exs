defmodule KuberaDB.Repo.Migrations.AddOwnerAppToApiKeyTable do
  use Ecto.Migration

  def change do
    alter table(:api_key) do
      add :owner_app, :string, null: false
    end

    create index(:api_key, [:owner_app])
  end
end
