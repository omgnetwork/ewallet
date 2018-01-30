defmodule EWalletDB.Repo.Migrations.AddAvatarToAccounts do
  use Ecto.Migration

  def change do
    alter table(:account) do
      add :avatar, :string
    end
  end
end
