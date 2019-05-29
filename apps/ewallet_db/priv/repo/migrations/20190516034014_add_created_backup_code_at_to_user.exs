defmodule EWalletDB.Repo.Migrations.AddCreatedBackupCodeAtToUser do
  use Ecto.Migration

  def change do
    alter table(:user) do
      add :backup_codes_created_at, :naive_datetime
    end
  end
end
