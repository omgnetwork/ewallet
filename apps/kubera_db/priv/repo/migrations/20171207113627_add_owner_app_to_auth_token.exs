defmodule KuberaDB.Repo.Migrations.AddOwnerAppToAuthTokenTable do
  use Ecto.Migration

  def change do
    alter table(:auth_token) do
      add :owner_app, :string, null: false
    end

    create index(:auth_token, [:owner_app])
  end
end
