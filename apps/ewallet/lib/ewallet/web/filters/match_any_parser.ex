defmodule EWallet.Web.MatchAnyParser do
  @moduledoc """
  Scopes an Ecto query with the "match_any" attribute.
  """
  alias EWallet.Web.{MatchParser, MatchAnyQuery}

  @spec to_query(Ecto.Queryable.t(), map(), [atom()]) :: Ecto.Queryable.t()
  def to_query(queryable, attrs, whitelist, mappings \\ %{})

  def to_query(queryable, %{"match_any" => inputs}, whitelist, mappings) do
    MatchParser.build_query(queryable, inputs, whitelist, false, MatchAnyQuery, mappings)
  end

  def to_query(queryable, _, _, _), do: queryable
end
