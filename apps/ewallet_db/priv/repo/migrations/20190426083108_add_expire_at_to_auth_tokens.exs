defmodule EWalletDB.Repo.Migrations.AddExpireAtToAuthTokens do
  use Ecto.Migration

  def change do
    alter table(:auth_token) do
      add :expire_at, :naive_datetime_usec, null: true
    end
  end
end
