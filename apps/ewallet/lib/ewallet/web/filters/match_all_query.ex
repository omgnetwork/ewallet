# Skipping cyclomatic complexity check for this file as the query conditions are unavoidable.
# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
defmodule EWallet.Web.MatchAllQuery do
  @moduledoc """
  Functions to build the actual query elements.
  """
  import Ecto.Query

  def do_filter(dynamic, field, :uuid, comparator, value) do
    case comparator do
      "eq" ->
        dynamic([q], fragment("?::text", field(q, ^field)) == ^value and ^dynamic)

      "neq" ->
        dynamic([q], fragment("?::text", field(q, ^field)) != ^value and ^dynamic)

      "contains" ->
        dynamic([q], ilike(fragment("?::text", field(q, ^field)), ^"%#{value}%") and ^dynamic)

      "starts_with" ->
        dynamic([q], ilike(fragment("?::text", field(q, ^field)), ^"#{value}%") and ^dynamic)

      _ ->
        {:error, :comparator_not_supported, field: field, comparator: comparator, value: value}
    end
  end

  def do_filter(dynamic, field, nil, comparator, nil = value) do
    case comparator do
      "eq" -> dynamic([q], is_nil(field(q, ^field)) and ^dynamic)
      "neq" -> dynamic([q], not is_nil(field(q, ^field)) and ^dynamic)
      _ -> {:error, :comparator_not_supported, field: field, comparator: comparator, value: value}
    end
  end

  def do_filter(dynamic, field, nil, comparator, value) do
    case comparator do
      "eq" -> dynamic([q], field(q, ^field) == ^value and ^dynamic)
      "neq" -> dynamic([q], field(q, ^field) != ^value and ^dynamic)
      "gt" -> dynamic([q], field(q, ^field) > ^value and ^dynamic)
      "gte" -> dynamic([q], field(q, ^field) >= ^value and ^dynamic)
      "lt" -> dynamic([q], field(q, ^field) < ^value and ^dynamic)
      "lte" -> dynamic([q], field(q, ^field) <= ^value and ^dynamic)
      "contains" -> dynamic([q], ilike(field(q, ^field), ^"%#{value}%") and ^dynamic)
      "starts_with" -> dynamic([q], ilike(field(q, ^field), ^"#{value}%") and ^dynamic)
      _ -> {:error, :comparator_not_supported, field: field, comparator: comparator, value: value}
    end
  end

  def do_filter_assoc(dynamic, 0, field, nil, comparator, nil = value) do
    case comparator do
      "eq" -> dynamic([q, a], is_nil(field(a, ^field)) and ^dynamic)
      "neq" -> dynamic([q, a], not is_nil(field(a, ^field)) and ^dynamic)
      _ -> {:error, :comparator_not_supported, field: field, comparator: comparator, value: value}
    end
  end

  def do_filter_assoc(dynamic, 0, field, nil, comparator, value) do
    case comparator do
      "eq" -> dynamic([q, a], field(a, ^field) == ^value and ^dynamic)
      "neq" -> dynamic([q, a], field(a, ^field) != ^value and ^dynamic)
      "gt" -> dynamic([q, a], field(a, ^field) > ^value and ^dynamic)
      "gte" -> dynamic([q, a], field(a, ^field) >= ^value and ^dynamic)
      "lt" -> dynamic([q, a], field(a, ^field) < ^value and ^dynamic)
      "lte" -> dynamic([q, a], field(a, ^field) <= ^value and ^dynamic)
      "contains" -> dynamic([q, a], ilike(field(a, ^field), ^"%#{value}%") and ^dynamic)
      "starts_with" -> dynamic([q, a], ilike(field(a, ^field), ^"#{value}%") and ^dynamic)
      _ -> {:error, :comparator_not_supported, field: field, comparator: comparator, value: value}
    end
  end

  def do_filter_assoc(dynamic, 1, field, nil, comparator, nil = value) do
    case comparator do
      "eq" -> dynamic([q, _, a], is_nil(field(a, ^field)) and ^dynamic)
      "neq" -> dynamic([q, _, a], not is_nil(field(a, ^field)) and ^dynamic)
      _ -> {:error, :comparator_not_supported, field: field, comparator: comparator, value: value}
    end
  end

  def do_filter_assoc(dynamic, 1, field, nil, comparator, value) do
    case comparator do
      "eq" -> dynamic([q, _, a], field(a, ^field) == ^value and ^dynamic)
      "neq" -> dynamic([q, _, a], field(a, ^field) != ^value and ^dynamic)
      "gt" -> dynamic([q, _, a], field(a, ^field) > ^value and ^dynamic)
      "gte" -> dynamic([q, _, a], field(a, ^field) >= ^value and ^dynamic)
      "lt" -> dynamic([q, _, a], field(a, ^field) < ^value and ^dynamic)
      "lte" -> dynamic([q, _, a], field(a, ^field) <= ^value and ^dynamic)
      "contains" -> dynamic([q, _, a], ilike(field(a, ^field), ^"%#{value}%") and ^dynamic)
      "starts_with" -> dynamic([q, _, a], ilike(field(a, ^field), ^"#{value}%") and ^dynamic)
      _ -> {:error, :comparator_not_supported, field: field, comparator: comparator, value: value}
    end
  end

  def do_filter_assoc(dynamic, 2, field, nil, comparator, nil = value) do
    case comparator do
      "eq" -> dynamic([q, _, _, a], is_nil(field(a, ^field)) and ^dynamic)
      "neq" -> dynamic([q, _, _, a], not is_nil(field(a, ^field)) and ^dynamic)
      _ -> {:error, :comparator_not_supported, field: field, comparator: comparator, value: value}
    end
  end

  def do_filter_assoc(dynamic, 2, field, nil, comparator, value) do
    case comparator do
      "eq" -> dynamic([q, _, _, a], field(a, ^field) == ^value and ^dynamic)
      "neq" -> dynamic([q, _, _, a], field(a, ^field) != ^value and ^dynamic)
      "gt" -> dynamic([q, _, _, a], field(a, ^field) > ^value and ^dynamic)
      "gte" -> dynamic([q, _, _, a], field(a, ^field) >= ^value and ^dynamic)
      "lt" -> dynamic([q, _, _, a], field(a, ^field) < ^value and ^dynamic)
      "lte" -> dynamic([q, _, _, a], field(a, ^field) <= ^value and ^dynamic)
      "contains" -> dynamic([q, _, _, a], ilike(field(a, ^field), ^"%#{value}%") and ^dynamic)
      "starts_with" -> dynamic([q, _, _, a], ilike(field(a, ^field), ^"#{value}%") and ^dynamic)
      _ -> {:error, :comparator_not_supported, field: field, comparator: comparator, value: value}
    end
  end

  def do_filter_assoc(dynamic, 3, field, nil, comparator, nil = value) do
    case comparator do
      "eq" -> dynamic([q, _, _, _, a], is_nil(field(a, ^field)) and ^dynamic)
      "neq" -> dynamic([q, _, _, _, a], not is_nil(field(a, ^field)) and ^dynamic)
      _ -> {:error, :comparator_not_supported, field: field, comparator: comparator, value: value}
    end
  end

  def do_filter_assoc(dynamic, 3, field, nil, comparator, value) do
    case comparator do
      "eq" ->
        dynamic([q, _, _, _, a], field(a, ^field) == ^value and ^dynamic)

      "neq" ->
        dynamic([q, _, _, _, a], field(a, ^field) != ^value and ^dynamic)

      "gt" ->
        dynamic([q, _, _, _, a], field(a, ^field) > ^value and ^dynamic)

      "gte" ->
        dynamic([q, _, _, _, a], field(a, ^field) >= ^value and ^dynamic)

      "lt" ->
        dynamic([q, _, _, _, a], field(a, ^field) < ^value and ^dynamic)

      "lte" ->
        dynamic([q, _, _, _, a], field(a, ^field) <= ^value and ^dynamic)

      "contains" ->
        dynamic([q, _, _, _, a], ilike(field(a, ^field), ^"%#{value}%") and ^dynamic)

      "starts_with" ->
        dynamic([q, _, _, _, a], ilike(field(a, ^field), ^"#{value}%") and ^dynamic)

      _ ->
        {:error, :comparator_not_supported, field: field, comparator: comparator, value: value}
    end
  end

  def do_filter_assoc(dynamic, 4, field, nil, comparator, nil = value) do
    case comparator do
      "eq" -> dynamic([q, _, _, _, _, a], is_nil(field(a, ^field)) and ^dynamic)
      "neq" -> dynamic([q, _, _, _, _, a], not is_nil(field(a, ^field)) and ^dynamic)
      _ -> {:error, :comparator_not_supported, field: field, comparator: comparator, value: value}
    end
  end

  def do_filter_assoc(dynamic, 4, field, nil, comparator, value) do
    case comparator do
      "eq" ->
        dynamic([q, _, _, _, _, a], field(a, ^field) == ^value and ^dynamic)

      "neq" ->
        dynamic([q, _, _, _, _, a], field(a, ^field) != ^value and ^dynamic)

      "gt" ->
        dynamic([q, _, _, _, _, a], field(a, ^field) > ^value and ^dynamic)

      "gte" ->
        dynamic([q, _, _, _, _, a], field(a, ^field) >= ^value and ^dynamic)

      "lt" ->
        dynamic([q, _, _, _, _, a], field(a, ^field) < ^value and ^dynamic)

      "lte" ->
        dynamic([q, _, _, _, _, a], field(a, ^field) <= ^value and ^dynamic)

      "contains" ->
        dynamic([q, _, _, _, _, a], ilike(field(a, ^field), ^"%#{value}%") and ^dynamic)

      "starts_with" ->
        dynamic([q, _, _, _, _, a], ilike(field(a, ^field), ^"#{value}%") and ^dynamic)

      _ ->
        {:error, :comparator_not_supported, field: field, comparator: comparator, value: value}
    end
  end
end
