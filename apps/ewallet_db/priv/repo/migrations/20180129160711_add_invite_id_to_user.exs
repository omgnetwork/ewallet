defmodule EWalletDB.Repo.Migrations.AddInviteIdToUser do
  use Ecto.Migration

  def change do
    alter table(:user) do
      add :invite_id, references(:invite, type: :uuid)
    end
  end
end
