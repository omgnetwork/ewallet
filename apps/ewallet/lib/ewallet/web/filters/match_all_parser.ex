defmodule EWallet.Web.MatchAllParser do
  @moduledoc """
  Scopes an Ecto query with the "match_all" attribute.
  """
  alias EWallet.Web.{MatchParser, MatchAllQuery}

  @spec to_query(Ecto.Queryable.t(), map(), [atom()], map()) :: Ecto.Queryable.t()
  def to_query(queryable, attrs, whitelist, mappings \\ %{})

  def to_query(queryable, %{"match_all" => []}, _, _), do: queryable

  def to_query(queryable, %{"match_all" => inputs}, whitelist, mappings) do
    MatchParser.build_query(queryable, inputs, whitelist, true, MatchAllQuery, mappings)
  end

  def to_query(queryable, _, _, _), do: queryable
end
