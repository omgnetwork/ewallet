defmodule KuberaDB.Repo.Migrations.CreateMembershipTable do
  use Ecto.Migration

  def change do
    create table(:membership, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, references(:user, type: :uuid)
      add :account_id, references(:account, type: :uuid)
      add :role_id, references(:role, type: :uuid)

      timestamps()
    end

    # Each user may have only one role per account at a given time
    create unique_index(:membership, [:user_id, :account_id])
  end
end
