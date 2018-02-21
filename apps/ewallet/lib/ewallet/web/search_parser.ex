defmodule EWallet.Web.SearchParser do
  @moduledoc """
  This module allows parsing of arbitrary attributes into a search query.
  It takes in a request's attributes, parses only the attributes needed for searching,
  then builds those attributes into a search query on top of the given `Ecto.Queryable`.
  """
  import Ecto.Query

  @doc """
  Parses search attributes and appends the resulting queries into the given queryable.

  To search for one term in all fields, use:
    %{"search_term" => "term"}

  For multiple search, use the following format:
    %{"search_terms" => %{ "field_name_1" => "term", "field_name_2" => "term2" }}

  Where "field_name" is in the list of available search fields.
  """
  @spec to_query(Ecto.Query.t, map, list) :: {Ecto.Query.t}
  def to_query(queryable, %{"search_term" => term}, fields) do
    Enum.reduce(fields, queryable, fn(field, query) ->
      build_search_query(query, field, term)
    end)
  end
  def to_query(queryable, %{"search_terms" => terms}, fields) do
    Enum.reduce(terms, queryable, fn({field, value}, query) ->
      case is_allowed_field?(fields, field) do
        nil    -> query
        field  -> build_search_query(query, field, value)
      end
    end)
  end
  def to_query(queryable, _, _), do: queryable

  defp is_allowed_field?(fields, field) do
    atom_field = String.to_atom(field)

    cond do
      Enum.member?(fields, {atom_field, :uuid}) -> {atom_field, :uuid}
      Enum.member?(fields, atom_field)          -> atom_field
      true                                      -> nil
    end
  end

  defp build_search_query(query, {field, :uuid}, term) do
    from q in query, or_where: ilike(fragment("?::text", field(q, ^field)), ^"%#{term}%")
  end
  defp build_search_query(query, field, term) do
    from q in query, or_where: ilike(field(q, ^field), ^"%#{term}%")
  end
end
