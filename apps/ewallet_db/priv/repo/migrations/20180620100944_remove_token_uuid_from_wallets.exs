defmodule EWalletDB.Repo.Migrations.RemoveTokenUUIDFromWallets do
  use Ecto.Migration

  def up do
    alter table(:wallet) do
      remove :token_uuid
    end
  end

  def down do
    alter table(:wallet) do
      add :token_uuid, references(:token, column: :uuid, type: :uuid)
    end
  end
end
