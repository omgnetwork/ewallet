defmodule EWalletDB.Repo.Migrations.AddTwoFAToUser do
  use Ecto.Migration

  def change do
    alter table(:user) do
      add :enabled_2fa_at, :naive_datetime
      add :secret_2fa_code, :string
      add(:hashed_backup_codes, {:array, :string}, default: [])
      add :used_backup_code_at, :naive_datetime
      add(:used_hashed_backup_codes, {:array, :string}, default: [])
    end
  end
end
