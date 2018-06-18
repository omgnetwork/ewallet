defmodule EWalletDB.Repo.Migrations.RenameEntryUuidToLocalLedgerTransactionUuid do
  use Ecto.Migration

  def up do
    rename table(:transaction), :entry_uuid, to: :local_ledger_uuid
  end

  def down do
    rename table(:transaction), :local_ledger_uuid, to: :entry_uuid
  end
end
