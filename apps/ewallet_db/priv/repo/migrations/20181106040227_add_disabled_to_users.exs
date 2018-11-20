defmodule EWalletDB.Repo.Migrations.AddDisabledToUsers do
  use Ecto.Migration

  def change do
    alter table(:user) do
      add :enabled, :boolean, null: false, default: true
    end
  end
end
