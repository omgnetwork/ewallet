defmodule EWalletDB.Repo.Migrations.AddEncryptedBackupCodesToUser do
  use Ecto.Migration

  def change do
    alter table(:user) do
      add :encrypted_backup_codes, {:array, :string}, default: []
    end
  end
end
