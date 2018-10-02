defmodule EWalletDB.Repo.Migrations.AddEnabledToForgetPasswordRequest do
  use Ecto.Migration

  def change do
    alter table(:forget_password_request) do
      add :enabled, :boolean, null: false, default: true
    end
  end
end
