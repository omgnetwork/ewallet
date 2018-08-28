defmodule EWallet.Web.FilterParser do
  @moduledoc """
  This module allows parsing of arbitrary attributes into a filtering query.
  It takes in a request's attributes, parses only the attributes needed for filtering,
  then builds those attributes into a filtering query on top of the given `Ecto.Queryable`.
  """
  import Ecto.Query

  @spec to_query(Ecto.Queryable.t(), map(), [atom()]) :: Ecto.Queryable.t()
  def to_query(queryable, %{"filters" => filters}, allowed) do
    parse_many(queryable, filters, allowed)
  end

  def to_query(queryable, _, _), do: queryable

  # ------------------------------
  # Parses all the filter inputs
  # ------------------------------

  defp parse_many({:error, _, _} = error, _, _), do: error

  defp parse_many(queryable, [filter | remaining], allowed) do
    queryable
    |> parse_one(filter, allowed)
    |> parse_many(remaining, allowed)
  end

  defp parse_many(queryable, [], _), do: queryable

  # ------------------------------
  # Parses a single filter
  # ------------------------------

  defp parse_one(
         queryable,
         %{"field" => field, "comparator" => comparator, "value" => value},
         allowed
       ) do
    atom_field = String.to_existing_atom(field)

    case Enum.member?(allowed, atom_field) do
      true ->
        build_query(queryable, atom_field, comparator, value)

      false ->
        {:error, :not_allowed, field}
    end
  rescue
    _ in ArgumentError -> {:error, :not_allowed, field}
  end

  defp parse_one(_queryable, params, _) do
    {:error, :missing_filter_param, params}
  end

  # ------------------------------
  # Build the query from the parsed filter
  # ------------------------------

  defp build_query(queryable, field, "eq", value) do
    queryable |> where([q], field(q, ^field) == ^value)
  end

  defp build_query(queryable, field, "neq", value) do
    queryable |> where([q], field(q, ^field) != ^value)
  end

  defp build_query(queryable, field, "gt", value) do
    queryable |> where([q], field(q, ^field) > ^value)
  end

  defp build_query(queryable, field, "gte", value) do
    queryable |> where([q], field(q, ^field) >= ^value)
  end

  defp build_query(queryable, field, "lt", value) do
    queryable |> where([q], field(q, ^field) < ^value)
  end

  defp build_query(queryable, field, "lte", value) do
    queryable |> where([q], field(q, ^field) <= ^value)
  end

  defp build_query(queryable, field, "contains", value) do
    queryable |> where([q], ilike(field(q, ^field), ^"%#{value}%"))
  end
end
