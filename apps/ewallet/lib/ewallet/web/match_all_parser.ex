defmodule EWallet.Web.MatchAllParser do
  @moduledoc """
  This module allows parsing of arbitrary attributes into a filtering query.
  It takes in a request's attributes, parses only the attributes needed for filtering,
  then builds those attributes into a filtering query on top of the given `Ecto.Queryable`.
  """
  import Ecto.Query
  import EWallet.Web.MatchAllParserHelper

  # Steps:
  # 1. Parse the list of `%{"field" => _, "comparator" => _, "value" => _}`
  #    into a list of `{field, subfield, type, comparator, value}` filter rules.
  # 2. Join the original queryable with the assocs needed to query for the parsed_input.
  #    Also build a map of positional reference of the joined assocs.
  # 3. Condition the joined queryable by the parsed_input.

  @spec to_query(Ecto.Queryable.t(), map(), [atom()]) :: Ecto.Queryable.t()
  def to_query(queryable, %{"match_all" => inputs}, whitelist) do
    with rules when is_list(rules) <- parse_rules(inputs, whitelist),
         {queryable, assoc_positions} <- join_assocs(queryable, rules),
         true <- Enum.count(assoc_positions) <= 5 || {:error, :too_many_associations},
         queryable <- filter(queryable, assoc_positions, rules),
         queryable <- distinct(queryable, true) do
      queryable
    else
      error -> error
    end
  end

  def to_query(queryable, _, _), do: queryable

  # Parses a list of arbitary `%{"field" => _, "comparator" => _, "value" => _}`
  # into a list of `{field, subfield, type, comparator, value}`.
  defp parse_rules(inputs, whitelist) do
    Enum.reduce_while(inputs, [], fn input, accumulator ->
      case parse_rule(input, whitelist) do
        {:error, _} = error ->
          {:halt, error}

        {:error, _, _} = error ->
          {:halt, error}

        parsed ->
          {:cont, [parsed | accumulator]}
      end
    end)
  end

  # ------------------------------
  # Parses a single filter
  # ------------------------------
  defp parse_rule(
         %{"field" => field, "comparator" => comparator, "value" => value},
         whitelist
       ) do
    fieldset = parse_fieldset(field)

    case find_field_definition(fieldset, whitelist) do
      nil ->
        {:error, :not_allowed, field}

      field_definition ->
        {field_definition, comparator, value}
    end
  end

  defp parse_rule(params, _) do
    {:error, :missing_filter_param, params}
  end

  @spec parse_fieldset(String.t()) ::
          atom() | {atom(), atom()} | {:error, :not_supported, String.t()}
  defp parse_fieldset(field) do
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
    # Handles non-existing atom
    _ in ArgumentError ->
      {:error, :not_allowed, field}
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

  defp join_assocs(queryable, rules) do
    {queryable, joined_assocs} =
      Enum.reduce(rules, {queryable, []}, fn rule, {queryable, joined_assocs} ->
        {field_definition, _comparator, _value} = rule

        case field_definition do
          {_field, _type} ->
            {queryable, joined_assocs}

          {field, _subfield, _type} ->
            queryable = join(queryable, :inner, [q], assoc in assoc(q, ^field))
            joined_assocs = [field | joined_assocs]

            {queryable, joined_assocs}
        end
      end)

    joined_assocs =
      joined_assocs
      |> Enum.reverse()
      |> Enum.with_index()

    {queryable, joined_assocs}
  end

  def filter(queryable, assoc_positions, rules) do
    dynamic =
      Enum.reduce(rules, true, fn rule, dynamic ->
        {field_definition, comparator, value} = rule

        case field_definition do
          {field, type} ->
            do_filter(dynamic, field, type, comparator, value)

          {field, subfield, type} ->
            position = assoc_positions[field]
            do_filter_assoc(dynamic, position, subfield, type, comparator, value)
        end
      end)

    from(queryable, where: ^dynamic)
  end
end
