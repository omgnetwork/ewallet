defmodule EWalletDB.Repo.Migrations.AddSymbolToMintedTokenId do
  use Ecto.Migration
  import Ecto.Query
  alias EWalletDB.Repo

  @table_name "minted_token"

  def up do
    for [uuid, id, symbol] <- get_all(@table_name) do
      id
      |> add_symbol(symbol)
      |> update_id(@table_name, uuid)
    end
  end

  def down do
    for [uuid, id, _symbol] <- get_all(@table_name) do
      id
      |> remove_symbol()
      |> update_id(@table_name, uuid)
    end
  end

  defp get_all(table_name) do
    query = from(t in table_name,
                 select: [t.uuid, t.id, t.symbol],
                 lock: "FOR UPDATE")

    Repo.all(query)
  end

  defp add_symbol(id, symbol) do
    # Add the symbol only if the pattern is strictly:
    # `<non_underscores>_<non_underscores>`
    String.replace(id, ~r/^([^_]+)_([^_]+)$/, "\\1_#{symbol}_\\2")
  end

  defp remove_symbol(id) do
    # Remove the symbol only if the pattern is strictly
    # `<non_underscores>_<non_underscores>_<non_underscores>`
    String.replace(id, ~r/^([^_]+)_([^_]+)_([^_]+)$/, "\\1_\\3")
  end

  defp update_id(id, table_name, uuid) do
    query = from(t in table_name,
                 where: t.uuid == ^uuid,
                 update: [set: [id: ^id]])

    Repo.update_all(query, [])
  end
end
