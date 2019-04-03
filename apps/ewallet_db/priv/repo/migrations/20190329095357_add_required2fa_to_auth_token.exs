defmodule EWalletDB.Repo.Migrations.AddRequired2faToAuthToken do
  use Ecto.Migration

  def change do
    alter table(:auth_token) do
      add :required_2fa, :boolean, default: false
    end
  end
end
