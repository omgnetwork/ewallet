defmodule EWalletDB.Repo.Migrations.RenameAccountExternalIdToId do
  use Ecto.Migration

  def up do
    rename table(:account), :external_id, to: :id
  end

  def down do
    rename table(:account), :id, to: :external_id
  end
end
