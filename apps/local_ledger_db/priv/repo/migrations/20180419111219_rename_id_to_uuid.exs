defmodule LocalLedgerDB.Repo.Migrations.RenameIdToUuid do
  use Ecto.Migration

  @tables [
    :balance,
    :cached_balance,
    :entry,
    :minted_token,
    :transaction
  ]

  def up do
    Enum.each(@tables, fn(table) ->
      rename table(table), :id, to: :uuid
    end)
  end

  def down do
    Enum.each(@tables, fn(table) ->
      rename table(table), :uuid, to: :id
    end)
  end
end
