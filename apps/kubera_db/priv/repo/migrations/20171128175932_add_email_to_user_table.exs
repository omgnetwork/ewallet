defmodule KuberaDB.Repo.Migrations.AddEmailToUserTable do
  use Ecto.Migration

  def change do
    alter table(:user) do
      add :email, :string
      add :password_hash, :string
    end

    create unique_index(:user, [:email])
  end
end
