defmodule ActivityLogger.Repo.Migrations.AddTargetAndOriginatorIdentifierInActivityLog do
  use Ecto.Migration

  def change do
    alter table(:activity_log) do
      add :target_identifier, :string
      add :originator_identifier, :string
    end

    create index(:activity_log, [:target_identifier, :target_type])
    create index(:activity_log, [:originator_identifier, :originator_type])
  end
end
