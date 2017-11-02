defmodule KuberaDB.Repo.Migrations.CreateAuthTokenTable do
  use Ecto.Migration

  def change do
    create table(:auth_token, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :token, :string, null: false
      add :user_id, references(:user, type: :uuid)
      add :expired, :boolean, null: false, default: false

      timestamps()
    end

    create unique_index(:auth_token, [:token])
  end
end
