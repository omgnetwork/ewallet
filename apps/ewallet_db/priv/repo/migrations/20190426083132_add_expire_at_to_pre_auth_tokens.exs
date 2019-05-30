defmodule EWalletDB.Repo.Migrations.AddExpireAtToPreAuthTokens do
  use Ecto.Migration

  def change do
    alter table(:pre_auth_token) do
      add :expired_at, :naive_datetime_usec, null: true
    end
  end
end
