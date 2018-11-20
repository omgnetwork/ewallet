defmodule EWalletDB.Repo.Migrations.CreateUpdateEmailRequest do
  use Ecto.Migration

  def change do
    create table(:update_email_request, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :email, :string, null: false
      add :token, :string, null: false
      add :enabled, :boolean, null: false, default: true

      add :user_uuid, references(:user, type: :uuid, column: :uuid)

      timestamps()
    end

    create unique_index(:update_email_request, [:token])
  end
end
