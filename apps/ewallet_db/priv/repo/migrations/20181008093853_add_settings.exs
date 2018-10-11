defmodule EWalletDB.Repo.Migrations.AddSettings do
  use Ecto.Migration

  def change do
    create table(:setting, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :id, :string, null: false

      add :key, :string, null: false
      add :data, :map
      add :encrypted_data, :binary
      add :type, :string, null: false
      add :description, :string
      add :options, :string
      add :parent, :string
      add :parent_value, :string
      add :secret, :boolean, null: false, default: false
      add :position, :integer, null: false, unique: true

      timestamps()
    end

    create unique_index(:setting, [:id])
    create unique_index(:setting, [:key])
    create unique_index(:setting, [:position])
  end
end
