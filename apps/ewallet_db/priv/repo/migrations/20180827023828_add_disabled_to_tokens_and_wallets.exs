defmodule EWalletDB.Repo.Migrations.AddDisabledToTokensAndWallets do
  use Ecto.Migration

  def change do
    alter table(:token) do
      add :enabled, :boolean, null: false, default: true
    end

    alter table(:wallet) do
      add :enabled, :boolean, null: false, default: true
    end
  end
end
