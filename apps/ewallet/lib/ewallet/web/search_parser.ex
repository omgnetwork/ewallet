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
  def to_query(queryable, %{"search_terms" => terms}, fields) when terms != nil do
    {_i, query} = Enum.reduce(terms, {0, queryable}, fn({field, value}, {index, query}) ->
      fields
      |> is_allowed_field?(field)
      |> build_search_query(index, query, value)
    end)

    query
  end
  def to_query(queryable, %{"search_term" => term}, fields) when term != nil do
    {_i, query} = Enum.reduce(fields, {0, queryable}, fn(field, {index, query}) ->
      build_search_query(field, index, query, term)
    end)

    query
  end
  def to_query(queryable, _, _), do: queryable

  defp is_allowed_field?(fields, field) do
    atom_field = String.to_existing_atom(field)

    cond do
      Enum.member?(fields, {atom_field, :uuid}) -> {atom_field, :uuid}
      Enum.member?(fields, atom_field)          -> atom_field
      true                                      -> nil
    end
  rescue
    _ in ArgumentError -> nil
  end

  defp build_search_query(_field, index, query, nil), do: {index, query}
  defp build_search_query(nil, index, query, _value), do: {index, query}
  defp build_search_query(field, index, query, value) do
    case index do
      0 -> {index + 1, build_and_search_query(query, field, value)}
      _ -> {index, build_or_search_query(query, field, value)}
    end
  end

  defp build_or_search_query(query, {field, :uuid}, term) do
    from q in query, or_where: ilike(fragment("?::text", field(q, ^field)), ^"%#{term}%")
  end
  defp build_or_search_query(query, field, term) do
    from q in query, or_where: ilike(field(q, ^field), ^"%#{term}%")
  end

  defp build_and_search_query(query, {field, :uuid}, term) do
    from q in query, where: ilike(fragment("?::text", field(q, ^field)), ^"%#{term}%")
  end
  defp build_and_search_query(query, field, term) do
    from q in query, where: ilike(field(q, ^field), ^"%#{term}%")
  end
end
