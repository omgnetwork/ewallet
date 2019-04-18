defmodule EWalletDB.Repo.Migrations.AddHashedBackupCodesToUser do
  use Ecto.Migration

  def change do
    alter table(:user) do
      add(:hashed_backup_codes, {:array, :string}, default: [])
    end
  end
end
