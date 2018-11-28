defmodule EWalletDB.Repo.Migrations.AddUsedAtAndExpiresAtToForgetPasswordRequest do
  use Ecto.Migration

  def change do
    alter table(:forget_password_request) do
      add :used_at, :naive_datetime
      add :expires_at, :naive_datetime
    end

    create index(:forget_password_request, [:enabled, :expires_at])
  end
end
