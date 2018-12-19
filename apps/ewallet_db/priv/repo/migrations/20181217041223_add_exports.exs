defmodule EWalletDB.Repo.Migrations.AddExports do
  use Ecto.Migration

  def change do
    create table(:export, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :id, :string, null: false

      add :schema, :string, null: false
      add :status, :string, null: false
      add :format, :string, null: false
      add :completion, :float, default: 0, null: false
      add :url, :string
      add :filename, :string
      add :path, :string
      add :params, :map
      add :failure_reason, :string
      add :estimated_size, :float
      add :total_count, :integer
      add :actual_size, :float
      add :adapter, :string
      add :user_uuid, references(:user, column: :uuid, type: :uuid)
      add :key_uuid, references(:key, column: :uuid, type: :uuid)

      timestamps()
    end

    create unique_index(:export, [:id])
    create index(:export, [:user_uuid])
    create index(:export, [:key_uuid])
  end
end
