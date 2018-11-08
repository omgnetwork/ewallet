defmodule EWallet.Web.MatchAllParser do
  @moduledoc """
  Scopes an Ecto query with the "match_all" attribute.
  """
  alias EWallet.Web.{MatchParser, MatchAllQuery}

  @spec to_query(Ecto.Queryable.t(), map(), [atom()]) :: Ecto.Queryable.t()
  def to_query(queryable, %{"match_all" => inputs}, whitelist) do
    MatchParser.build_query(queryable, inputs, whitelist, true, MatchAllQuery)
  end

  def to_query(queryable, _, _), do: queryable
end
