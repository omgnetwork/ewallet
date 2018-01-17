defmodule EWalletDB.Repo.Migrations.AddAccountIDToMints do
  use Ecto.Migration

  def change do
    alter table(:mint) do
      add :account_id, references(:account, type: :uuid)
    end
  end
end
