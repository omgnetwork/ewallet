defmodule EWalletDB.Repo.Migrations.AddEnabled2faAtToUser do
  use Ecto.Migration

  def change do
    alter table(:user) do
      add :enabled_2fa_at, :naive_datetime
    end
  end
end
