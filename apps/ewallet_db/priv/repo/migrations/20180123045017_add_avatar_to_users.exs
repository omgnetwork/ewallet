defmodule EWalletDB.Repo.Migrations.AddAvatarToUsers do
  use Ecto.Migration

  def change do
    alter table(:user) do
      add :avatar, :string
    end
  end
end
