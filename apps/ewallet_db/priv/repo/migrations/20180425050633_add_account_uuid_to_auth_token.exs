defmodule EWalletDB.Repo.Migrations.AddAccountUUIDToAuthToken do
  use Ecto.Migration

  def change do
    alter table(:auth_token) do
      add :account_uuid, references(:account, type: :uuid, column: :uuid)
    end
  end
end
