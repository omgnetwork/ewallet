defmodule EWalletDB.Repo.Migrations.CreateInviteTable do
  use Ecto.Migration

  def change do
    create table(:invite, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :token, :string, null: false
      timestamps()
    end
  end
end
