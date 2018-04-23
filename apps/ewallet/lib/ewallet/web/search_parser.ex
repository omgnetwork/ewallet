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
  @spec to_query(Ecto.Queryable.t(), map(), [atom()]) :: Ecto.Queryable.t()
  @spec to_query(Ecto.Queryable.t(), map(), [atom()], map()) :: Ecto.Queryable.t()
  def to_query(queryable, terms, fields, mapping \\ %{})

  def to_query(queryable, %{"search_terms" => terms}, fields, mapping) when terms != nil do
    {_i, query} =
      Enum.reduce(terms, {0, queryable}, fn {field, value}, {index, query} ->
        field
        |> map_field(mapping)
        |> allowed?(fields)
        |> build_search_query(index, query, value)
      end)

    query
  end

  def to_query(queryable, %{"search_term" => term}, fields, _mapping) when term != nil do
    {_i, query} =
      Enum.reduce(fields, {0, queryable}, fn field, {index, query} ->
        build_search_query(field, index, query, term)
      end)

    query
  end

  def to_query(queryable, _, _, _), do: queryable

  defp map_field(original, mapping) do
    case mapping[original] do
      nil -> original
      mapped -> mapped
    end
  end

  defp allowed?(field, allowed_fields) when is_binary(field) do
    field
    |> String.to_existing_atom()
    |> allowed?(allowed_fields)
  rescue
    _ in ArgumentError -> nil
  end

  defp allowed?(field, allowed_fields) do
    cond do
      Enum.member?(allowed_fields, {field, :uuid}) -> {field, :uuid}
      Enum.member?(allowed_fields, field) -> field
      true -> nil
    end
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
    from(q in query, or_where: ilike(fragment("?::text", field(q, ^field)), ^"%#{term}%"))
  end

  defp build_or_search_query(query, field, term) do
    from(q in query, or_where: ilike(field(q, ^field), ^"%#{term}%"))
  end

  defp build_and_search_query(query, {field, :uuid}, term) do
    from(q in query, where: ilike(fragment("?::text", field(q, ^field)), ^"%#{term}%"))
  end

  defp build_and_search_query(query, field, term) do
    from(q in query, where: ilike(field(q, ^field), ^"%#{term}%"))
  end
end
