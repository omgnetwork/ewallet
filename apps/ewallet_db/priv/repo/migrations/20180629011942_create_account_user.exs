defmodule EWalletDB.Repo.Migrations.CreateAccountUser do
  use Ecto.Migration

  def change do
    create table(:account_user, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :account_uuid, references(:account, type: :uuid, column: :uuid), null: false
      add :user_uuid, references(:user, type: :uuid, column: :uuid), null: false
      timestamps()
    end

    create unique_index(:account_user, [:account_uuid, :user_uuid])
    create index(:account_user, [:user_uuid])
  end
end
