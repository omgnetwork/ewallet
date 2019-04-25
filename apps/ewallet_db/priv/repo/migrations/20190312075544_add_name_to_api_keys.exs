defmodule EWalletDB.Repo.Migrations.AddNameToAPIKeys do
  use Ecto.Migration

  def change do
    alter table(:api_key) do
      add :name, :string
    end
  end
end
