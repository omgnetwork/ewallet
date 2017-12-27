defmodule KuberaDB.Repo.Migrations.AlterUsernameNullableInUserTable do
  use Ecto.Migration

  def up do
    alter table(:user) do
      modify :username, :string, null: true
    end
  end

  def down do
    alter table(:user) do
      modify :username, :string, null: false
    end
  end
end
