defmodule EWalletDB.Repo.Migrations.CreateCategoryTable do
  use Ecto.Migration

  def change do
    create table(:category, primary_key: false) do
      add :id, :string, null: false
      add :uuid, :uuid, primary_key: true
      add :name, :string, null: false
      add :description, :string
      timestamps()
      add :deleted_at, :naive_datetime
    end

    create unique_index(:category, [:name])
    create index(:category, [:deleted_at])

    # Create the pivot table to support many-to-many account <-> category relationship
    create table(:account_category, primary_key: false) do
      add :account_uuid, references(:account, column: :uuid, type: :uuid)
      add :category_uuid, references(:category, column: :uuid, type: :uuid)
    end

    create unique_index(:account_category, [:account_uuid, :category_uuid])
  end
end
