defmodule ActivityLogger.Repo.Migrations.AddTargetAndOriginatorIdInActivityLog do
  use Ecto.Migration

  def change do
    alter table(:activity_log) do
      add :target_id, :string
      add :originator_id, :string
    end

    create index(:activity_log, [:target_id, :target_type])
    create index(:activity_log, [:originator_id, :originator_type])
  end
end
