defmodule EWalletDB.Repo.Migrations.AddSuccessUrlToInvite do
  use Ecto.Migration

  def change do
    alter table(:invite) do
      add :success_url, :string
    end
  end
end
