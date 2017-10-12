defmodule KuberaDB.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create table(:user, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :username, :string, null: false
      add :provider_user_id, :string
      add :metadata, :map
      timestamps()
    end

    create unique_index(:user, [:username])
    create unique_index(:user, [:provider_user_id])
  end
end
