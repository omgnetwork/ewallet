defmodule EWalletDB.Repo.Migrations.AddIsAdminToUser do
  use Ecto.Migration

  def change do
    alter table(:user) do
      add :is_admin, :boolean, default: false, null: false
    end
  end
end
