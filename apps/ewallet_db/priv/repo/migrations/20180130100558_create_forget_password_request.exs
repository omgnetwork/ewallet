defmodule EWalletDB.Repo.Migrations.CreateForgetPasswordRequest do
  use Ecto.Migration

  def change do
    create table(:forget_password_request, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :token, :string, null: false
      add :user_id, references(:user, type: :uuid)
      timestamps()
    end
  end
end
