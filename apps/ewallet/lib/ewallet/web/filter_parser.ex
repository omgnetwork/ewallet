defmodule EWallet.Web.FilterParser do
  @moduledoc """
  This module allows parsing of arbitrary attributes into a filtering query.
  It takes in a request's attributes, parses only the attributes needed for filtering,
  then builds those attributes into a filtering query on top of the given `Ecto.Queryable`.
  """
  import Ecto.Query

  @spec to_query(Ecto.Queryable.t(), map(), [atom()]) :: Ecto.Queryable.t()
  def to_query(queryable, %{"filters" => filters}, whitelist) do
    parse_many(queryable, filters, whitelist)
  end

  def to_query(queryable, _, _), do: queryable

  # ------------------------------
  # Parses all the filter inputs
  # ------------------------------

  defp parse_many({:error, _, _} = error, _, _), do: error

  defp parse_many(queryable, [filter | remaining], whitelist) do
    queryable
    |> parse_one(filter, whitelist)
    |> parse_many(remaining, whitelist)
  end

  defp parse_many(queryable, [], _), do: queryable

  # ------------------------------
  # Parses a single filter
  # ------------------------------

  defp parse_one(
         queryable,
         %{"field" => field, "comparator" => comparator, "value" => value},
         whitelist
       ) do
    parsed = parse_field(field)

    case find_field_definition(parsed, whitelist) do
      nil ->
        {:error, :not_allowed, field}

      field_definition ->
        build_query(queryable, field_definition, comparator, value)
    end
  end

  defp parse_one(_queryable, params, _) do
    {:error, :missing_filter_param, params}
  end

  @spec parse_field(String.t()) ::
          atom() | {atom(), atom()} | {:error, :not_supported, String.t()}
  defp parse_field(field) do
    splitted = String.split(field, ".")

    # Avoid unneccessarily counting deeply nested values by taking out only 3 items.
    case Enum.take(splitted, 3) do
      [field] ->
        String.to_existing_atom(field)

      [field, subfield] ->
        {String.to_existing_atom(field), String.to_existing_atom(subfield)}

      [field, _subfield, _too_deep] ->
        {:error, :not_supported, field}
    end
  rescue
    _ in ArgumentError -> {:error, :not_allowed, field}
  end

  # Find the field definition from the whitelist.
  #
  # Return values:
  # - `{field, nil}` when the definition does not indicate a type
  # - `{field, type}` when the definition indicates a type
  # - `{field, subfield, nil}` when the definition does not indicate a type
  # - `{field, subfield, type}` when the definition indicates a type
  # - `nil` when no matching field definitions could be found
  @spec find_field_definition(atom(), list()) :: {atom(), atom()} | {atom(), nil} | nil
  @spec find_field_definition({atom(), atom()}, list()) ::
          {atom(), atom(), atom()} | {atom(), atom(), nil} | nil
  defp find_field_definition(field_or_tuple, whitelist) when is_list(whitelist) do
    Enum.find_value(whitelist, fn w -> get_field_definition(field_or_tuple, w) end)
  end

  # If the parent field matches, find the definition of the `subfield` in the `allowed_subfields`
  defp get_field_definition({field, subfield}, {field, allowed_subfields}) do
    case find_field_definition(subfield, allowed_subfields) do
      {_, nil} -> {field, subfield, nil}
      {_, type} -> {field, subfield, type}
      nil -> nil
    end
  end

  # Returns `{field, nil}` if the type is not given
  defp get_field_definition(field, field), do: {field, nil}

  # Returns `{field, type}` if the type is given
  defp get_field_definition(field, {field, type}), do: {field, type}

  # Returns nil if the field does not match
  defp get_field_definition(_, _), do: nil

  # ------------------------------
  # Build the query from the parsed filter
  # ------------------------------

  # is equal to
  defp build_query(queryable, {field, subfield, nil}, "eq", value) do
    queryable
    |> join(:inner, [q], assoc in assoc(q, ^field))
    |> where([q, assoc], field(assoc, ^subfield) == ^value)
  end

  defp build_query(queryable, {field, :uuid}, "eq", value) do
    queryable |> where([q], fragment("?::text", field(q, ^field)) == ^value)
  end

  defp build_query(queryable, {field, nil}, "eq", value) do
    queryable |> where([q], field(q, ^field) == ^value)
  end

  # is not equal to
  defp build_query(queryable, {field, subfield, nil}, "neq", value) do
    queryable
    |> join(:inner, [q], assoc in assoc(q, ^field))
    |> where([q, assoc], field(assoc, ^subfield) != ^value)
  end

  defp build_query(queryable, {field, :uuid}, "neq", value) do
    queryable |> where([q], fragment("?::text", field(q, ^field)) != ^value)
  end

  defp build_query(queryable, {field, nil}, "neq", value) do
    queryable |> where([q], field(q, ^field) != ^value)
  end

  # is greater than
  defp build_query(queryable, {field, subfield, nil}, "gt", value) do
    queryable
    |> join(:inner, [q], assoc in assoc(q, ^field))
    |> where([q, assoc], field(assoc, ^subfield) > ^value)
  end

  defp build_query(queryable, {field, nil}, "gt", value) do
    queryable |> where([q], field(q, ^field) > ^value)
  end

  # is greater or equal to
  defp build_query(queryable, {field, subfield, nil}, "gte", value) do
    queryable
    |> join(:inner, [q], assoc in assoc(q, ^field))
    |> where([q, assoc], field(assoc, ^subfield) >= ^value)
  end

  defp build_query(queryable, {field, nil}, "gte", value) do
    queryable |> where([q], field(q, ^field) >= ^value)
  end

  # is less than
  defp build_query(queryable, {field, subfield, nil}, "lt", value) do
    queryable
    |> join(:inner, [q], assoc in assoc(q, ^field))
    |> where([q, assoc], field(assoc, ^subfield) < ^value)
  end

  defp build_query(queryable, {field, nil}, "lt", value) do
    queryable |> where([q], field(q, ^field) < ^value)
  end

  # is less than or equal to
  defp build_query(queryable, {field, subfield, nil}, "lte", value) do
    queryable
    |> join(:inner, [q], assoc in assoc(q, ^field))
    |> where([q, assoc], field(assoc, ^subfield) <= ^value)
  end

  defp build_query(queryable, {field, nil}, "lte", value) do
    queryable |> where([q], field(q, ^field) <= ^value)
  end

  # contains
  defp build_query(queryable, {field, subfield, nil}, "contains", value) do
    queryable
    |> join(:inner, [q], assoc in assoc(q, ^field))
    |> where([q, assoc], ilike(field(assoc, ^subfield), ^"%#{value}%"))
  end

  defp build_query(queryable, {field, :uuid}, "contains", value) do
    queryable |> where([q], ilike(fragment("?::text", field(q, ^field)), ^"%#{value}%"))
  end

  defp build_query(queryable, {field, nil}, "contains", value) do
    queryable |> where([q], ilike(field(q, ^field), ^"%#{value}%"))
  end
end
