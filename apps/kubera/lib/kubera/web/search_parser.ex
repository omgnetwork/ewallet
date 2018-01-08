defmodule Kubera.Web.SearchParser do
  @moduledoc """
  This module allows parsing of arbitrary attributes into a search query.
  It takes in a request's attributes, parses only the attributes needed for searching,
  then builds those attributes into a search query on top of the given `Ecto.Queryable`.
  """
  import Ecto.Query

  @doc """
  Parses search attributes and appends the resulting queries into the given queryable.
  """
  @spec to_query(Ecto.Query.t, map, list) :: {Ecto.Query.t}
  def to_query(queryable, %{"search_term" => term}, fields) do
    Enum.reduce(fields, queryable, fn(field, query) ->
      build_search_query(query, field, term)
    end)
  end
  def to_query(queryable, _, _), do: queryable

  defp build_search_query(query, {field, :uuid}, term) do
    from q in query, or_where: ilike(fragment("?::text", field(q, ^field)), ^"%#{term}%")
  end
  defp build_search_query(query, field, term) do
    from q in query, or_where: ilike(field(q, ^field), ^"%#{term}%")
  end
end
