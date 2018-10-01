defmodule EWalletDB.Repo.Migrations.AddFullNameAndDisplayNameToUser do
  use Ecto.Migration

  def change do
    alter table(:user) do
      add :full_name, :string
      add :display_name, :string
    end
  end
end
