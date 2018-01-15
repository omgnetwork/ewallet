defmodule CaishenDB.Repo.Migrations.AddCorrelationIdToEntries do
  use Ecto.Migration

  def change do
    alter table(:entry) do
      add :correlation_id, :string, null: false
    end

    create unique_index(:entry, [:correlation_id])
  end
end
