defmodule EWalletDB.Repo.Migrations.RemoveEncryptionVersion do
  use Ecto.Migration

  def up do
    remove_encryption_version(:account)
    remove_encryption_version(:token)
    remove_encryption_version(:transaction_consumption)
    remove_encryption_version(:transaction_request)
    remove_encryption_version(:transfer)
    remove_encryption_version(:user)
    remove_encryption_version(:wallet)
  end

  def down do
    add_encryption_version(:account)
    add_encryption_version(:token)
    add_encryption_version(:transaction_consumption)
    add_encryption_version(:transaction_request)
    add_encryption_version(:transfer)
    add_encryption_version(:user)
    add_encryption_version(:wallet)
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
