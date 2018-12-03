defmodule ActivityLogger.Repo.Migrations.RenameAuditToActivityLogger do
  use Ecto.Migration

  def change do
    rename table(:audit), to: table(:activity_log)
  end
end
