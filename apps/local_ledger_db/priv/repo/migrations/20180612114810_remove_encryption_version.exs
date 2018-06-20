defmodule LocalLedgerDB.Repo.Migrations.RemoveEncryptionVersion do
  use Ecto.Migration

  def up do
    remove_encryption_version(:entry)
    remove_encryption_version(:token)
    remove_encryption_version(:wallet)
  end

  def down do
    add_encryption_version(:wallet)
    add_encryption_version(:token)
    add_encryption_version(:entry)
  end

  # priv

  defp remove_encryption_version(table_name) do
    alter table(table_name) do
      remove :encryption_version
    end
  end

  defp add_encryption_version(table_name) do
    alter table(table_name) do
      add :encryption_version, :binary
    end

    create index(table_name, [:encryption_version])
  end
end
