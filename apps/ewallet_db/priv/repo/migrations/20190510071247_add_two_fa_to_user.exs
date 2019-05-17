defmodule EWalletDB.Repo.Migrations.AddTwoFAToUser do
  use Ecto.Migration

  def change do
    alter table(:user) do
      add :enabled_2fa_at, :naive_datetime
      add :secret_2fa_code, :string
    end
  end
end
