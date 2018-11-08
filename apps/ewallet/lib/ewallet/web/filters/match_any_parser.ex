defmodule EWallet.Web.MatchAnyParser do
  @moduledoc """
  Scopes an Ecto query with the "match_any" attribute.
  """
  alias EWallet.Web.{MatchParser, MatchAnyQuery}

  @spec to_query(Ecto.Queryable.t(), map(), [atom()]) :: Ecto.Queryable.t()
  def to_query(queryable, %{"match_any" => inputs}, whitelist) do
    MatchParser.build_query(queryable, inputs, whitelist, false, MatchAnyQuery)
  end

  def to_query(queryable, _, _), do: queryable
end
