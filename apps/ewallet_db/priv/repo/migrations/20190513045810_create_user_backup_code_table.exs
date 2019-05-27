defmodule EWalletDB.Repo.Migrations.CreateUserBackupCodeTable do
  use Ecto.Migration

  def change do
    create table(:user_backup_code, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add(:hashed_backup_code, :string)
      add(:used_at, :naive_datetime)
      add(:user_uuid, references(:user, type: :uuid, column: :uuid))
      timestamps()
    end
  end
end
