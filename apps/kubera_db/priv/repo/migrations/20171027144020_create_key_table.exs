defmodule KuberaDB.Repo.Migrations.CreateKeyTable do
  use Ecto.Migration

  def change do
    create table(:key, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :access_key, :string, null: false
      add :secret_key, :string, null: false
      add :account_id, references(:account, type: :uuid)

      timestamps()
    end

    create unique_index(:key, [:access_key, :secret_key])
  end
end
