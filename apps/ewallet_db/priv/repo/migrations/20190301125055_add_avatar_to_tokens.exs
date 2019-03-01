defmodule EWalletDB.Repo.Migrations.AddAvatarToTokens do
  use Ecto.Migration

  def change do
    alter table(:token) do
      add :avatar, :string
    end
  end
end
