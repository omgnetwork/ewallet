# Skipping cyclomatic complexity check for this file as the query conditions are unavoidable.
# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
defmodule EWallet.Web.MatchAnyParserHelper do
  @moduledoc """
  Functions to build the actual query elements.
  """
  import Ecto.Query

  def do_filter(dynamic, field, :uuid, comparator, value) do
    case comparator do
      "eq" ->
        dynamic([q], fragment("?::text", field(q, ^field)) == ^value or ^dynamic)

      "neq" ->
        dynamic([q], fragment("?::text", field(q, ^field)) != ^value or ^dynamic)

      "contains" ->
        dynamic([q], ilike(fragment("?::text", field(q, ^field)), ^"%#{value}%") or ^dynamic)

      "starts_with" ->
        dynamic([q], ilike(fragment("?::text", field(q, ^field)), ^"#{value}%") or ^dynamic)
    end
  end

  def do_filter(dynamic, field, nil, comparator, value) do
    case comparator do
      "eq" -> dynamic([q], field(q, ^field) == ^value or ^dynamic)
      "neq" -> dynamic([q], field(q, ^field) != ^value or ^dynamic)
      "gt" -> dynamic([q], field(q, ^field) > ^value or ^dynamic)
      "gte" -> dynamic([q], field(q, ^field) >= ^value or ^dynamic)
      "lt" -> dynamic([q], field(q, ^field) < ^value or ^dynamic)
      "lte" -> dynamic([q], field(q, ^field) <= ^value or ^dynamic)
      "contains" -> dynamic([q], ilike(field(q, ^field), ^"%#{value}%") or ^dynamic)
      "starts_with" -> dynamic([q], ilike(field(q, ^field), ^"#{value}%") or ^dynamic)
    end
  end

  def do_filter_assoc(dynamic, 0, field, nil, comparator, value) do
    case comparator do
      "eq" -> dynamic([q, a], field(a, ^field) == ^value or ^dynamic)
      "neq" -> dynamic([q, a], field(a, ^field) != ^value or ^dynamic)
      "gt" -> dynamic([q, a], field(a, ^field) > ^value or ^dynamic)
      "gte" -> dynamic([q, a], field(a, ^field) >= ^value or ^dynamic)
      "lt" -> dynamic([q, a], field(a, ^field) < ^value or ^dynamic)
      "lte" -> dynamic([q, a], field(a, ^field) <= ^value or ^dynamic)
      "contains" -> dynamic([q, a], ilike(field(a, ^field), ^"%#{value}%") or ^dynamic)
      "starts_with" -> dynamic([q, a], ilike(field(a, ^field), ^"#{value}%") or ^dynamic)
    end
  end

  def do_filter_assoc(dynamic, 1, field, nil, comparator, value) do
    case comparator do
      "eq" -> dynamic([q, _, a], field(a, ^field) == ^value or ^dynamic)
      "neq" -> dynamic([q, _, a], field(a, ^field) != ^value or ^dynamic)
      "gt" -> dynamic([q, _, a], field(a, ^field) > ^value or ^dynamic)
      "gte" -> dynamic([q, _, a], field(a, ^field) >= ^value or ^dynamic)
      "lt" -> dynamic([q, _, a], field(a, ^field) < ^value or ^dynamic)
      "lte" -> dynamic([q, _, a], field(a, ^field) <= ^value or ^dynamic)
      "contains" -> dynamic([q, _, a], ilike(field(a, ^field), ^"%#{value}%") or ^dynamic)
      "starts_with" -> dynamic([q, _, a], ilike(field(a, ^field), ^"#{value}%") or ^dynamic)
    end
  end

  def do_filter_assoc(dynamic, 2, field, nil, comparator, value) do
    case comparator do
      "eq" -> dynamic([q, _, _, a], field(a, ^field) == ^value or ^dynamic)
      "neq" -> dynamic([q, _, _, a], field(a, ^field) != ^value or ^dynamic)
      "gt" -> dynamic([q, _, _, a], field(a, ^field) > ^value or ^dynamic)
      "gte" -> dynamic([q, _, _, a], field(a, ^field) >= ^value or ^dynamic)
      "lt" -> dynamic([q, _, _, a], field(a, ^field) < ^value or ^dynamic)
      "lte" -> dynamic([q, _, _, a], field(a, ^field) <= ^value or ^dynamic)
      "contains" -> dynamic([q, _, _, a], ilike(field(a, ^field), ^"%#{value}%") or ^dynamic)
      "starts_with" -> dynamic([q, _, _, a], ilike(field(a, ^field), ^"#{value}%") or ^dynamic)
    end
  end

  def do_filter_assoc(dynamic, 3, field, nil, comparator, value) do
    case comparator do
      "eq" -> dynamic([q, _, _, _, a], field(a, ^field) == ^value or ^dynamic)
      "neq" -> dynamic([q, _, _, _, a], field(a, ^field) != ^value or ^dynamic)
      "gt" -> dynamic([q, _, _, _, a], field(a, ^field) > ^value or ^dynamic)
      "gte" -> dynamic([q, _, _, _, a], field(a, ^field) >= ^value or ^dynamic)
      "lt" -> dynamic([q, _, _, _, a], field(a, ^field) < ^value or ^dynamic)
      "lte" -> dynamic([q, _, _, _, a], field(a, ^field) <= ^value or ^dynamic)
      "contains" -> dynamic([q, _, _, _, a], ilike(field(a, ^field), ^"%#{value}%") or ^dynamic)
      "starts_with" -> dynamic([q, _, _, _, a], ilike(field(a, ^field), ^"#{value}%") or ^dynamic)
    end
  end

  def do_filter_assoc(dynamic, 4, field, nil, comparator, value) do
    case comparator do
      "eq" ->
        dynamic([q, _, _, _, _, a], field(a, ^field) == ^value or ^dynamic)

      "neq" ->
        dynamic([q, _, _, _, _, a], field(a, ^field) != ^value or ^dynamic)

      "gt" ->
        dynamic([q, _, _, _, _, a], field(a, ^field) > ^value or ^dynamic)

      "gte" ->
        dynamic([q, _, _, _, _, a], field(a, ^field) >= ^value or ^dynamic)

      "lt" ->
        dynamic([q, _, _, _, _, a], field(a, ^field) < ^value or ^dynamic)

      "lte" ->
        dynamic([q, _, _, _, _, a], field(a, ^field) <= ^value or ^dynamic)

      "contains" ->
        dynamic([q, _, _, _, _, a], ilike(field(a, ^field), ^"%#{value}%") or ^dynamic)

      "starts_with" ->
        dynamic([q, _, _, _, _, a], ilike(field(a, ^field), ^"#{value}%") or ^dynamic)
    end
  end
end
