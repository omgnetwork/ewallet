defmodule ActivityLogger.Repo.Migrations.RenameEncryptedMetadataToEncryptedChanges do
  use Ecto.Migration

  def change do
    rename table(:activity_log), :target_encrypted_metadata, to: :target_encrypted_changes
  end
end
