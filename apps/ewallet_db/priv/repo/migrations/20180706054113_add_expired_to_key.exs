defmodule EWalletDB.Repo.Migrations.AddExpiredToKey do
  use Ecto.Migration

  def change do
    alter table(:key) do
      add :expired, :boolean, null: false, default: false
    end
  end
end
