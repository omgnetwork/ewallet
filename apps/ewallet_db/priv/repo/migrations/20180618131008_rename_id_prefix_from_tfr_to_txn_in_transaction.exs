defmodule EWalletDB.Repo.Migrations.RenameIdPrefixFromTfrToTxnInTransaction do
  use Ecto.Migration
  import Ecto.Query
  alias EWalletDB.Repo

  @table_name "transaction"
  @from_prefix "tfr_"
  @to_prefix "txn_"

  defp get_all(table_name) do
    query = from(t in table_name,
                 select: [t.uuid, t.id],
                 lock: "FOR UPDATE")

    Repo.all(query)
  end

  def up do
    for [uuid, id] <- get_all(@table_name) do
      id
      |> String.replace_prefix(@from_prefix, @to_prefix)
      |> update_id(@table_name, uuid)
    end
  end

  def down do
    for [uuid, id] <- get_all(@table_name) do
      id
      |> String.replace_prefix(@to_prefix, @from_prefix)
      |> update_id(@table_name, uuid)
    end
  end

  defp update_id(id, table_name, uuid) do
    query = from(t in table_name,
                 where: t.uuid == ^uuid,
                 update: [set: [id: ^id]])

    Repo.update_all(query, [])
  end
end
