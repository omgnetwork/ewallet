defmodule EWalletDB.Repo.Migrations.AddNameForKeys do
  use Ecto.Migration

  def change do
    alter table(:key) do
      add :name, :string
    end
  end
end
