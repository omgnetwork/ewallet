defmodule EWalletDB.Repo.Migrations.AddPreTokenToAuthTokens do
  use Ecto.Migration

  def change do
    alter table(:auth_token) do
      add :pre_token, :string
    end
  end
end
