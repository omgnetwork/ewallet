defmodule KuberaDB.Repo.Migrations.CreateMembershipTable do
  use Ecto.Migration

  def change do
    create table(:membership, primary_key: false) do
      add :account_id, references(:account, type: :uuid)
      add :user_id, references(:user, type: :uuid)
      add :role_id, references(:role, type: :uuid)

      timestamps()
    end

    create unique_index(:membership, [:account_id, :user_id, :role_id])
  end
end
