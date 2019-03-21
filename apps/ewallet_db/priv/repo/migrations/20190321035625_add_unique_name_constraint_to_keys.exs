defmodule EWalletDB.Repo.Migrations.AddUniqueNameConstraintToKeys do
  use Ecto.Migration

  def change do
    create unique_index(:key, [:name])
    create unique_index(:api_key, [:name])
  end
end
