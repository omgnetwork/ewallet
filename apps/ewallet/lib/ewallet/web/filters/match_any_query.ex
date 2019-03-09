# Copyright 2018 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Skipping cyclomatic complexity check for this file as the query conditions are unavoidable.
# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
defmodule EWallet.Web.MatchAnyQuery do
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

      _ ->
        {:error, :comparator_not_supported, field: field, comparator: comparator, value: value}
    end
  end

  def do_filter(dynamic, field, nil, comparator, nil = value) do
    case comparator do
      "eq" -> dynamic([q], is_nil(field(q, ^field)) or ^dynamic)
      "neq" -> dynamic([q], not is_nil(field(q, ^field)) or ^dynamic)
      _ -> {:error, :comparator_not_supported, field: field, comparator: comparator, value: value}
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
      _ -> {:error, :comparator_not_supported, field: field, comparator: comparator, value: value}
    end
  end

  def do_filter_assoc(dynamic, position, field, nil, comparator, nil = value) do
    case comparator do
      "eq" -> dynamic([{a, position}], is_nil(field(a, ^field)) or ^dynamic)
      "neq" -> dynamic([{a, position}], not is_nil(field(a, ^field)) or ^dynamic)
      _ -> {:error, :comparator_not_supported, field: field, comparator: comparator, value: value}
    end
  end

  def do_filter_assoc(dynamic, position, field, nil, comparator, value) do
    case comparator do
      "eq" -> dynamic([{a, position}], field(a, ^field) == ^value or ^dynamic)
      "neq" -> dynamic([{a, position}], field(a, ^field) != ^value or ^dynamic)
      "gt" -> dynamic([{a, position}], field(a, ^field) > ^value or ^dynamic)
      "gte" -> dynamic([{a, position}], field(a, ^field) >= ^value or ^dynamic)
      "lt" -> dynamic([{a, position}], field(a, ^field) < ^value or ^dynamic)
      "lte" -> dynamic([{a, position}], field(a, ^field) <= ^value or ^dynamic)
      "contains" -> dynamic([{a, position}], ilike(field(a, ^field), ^"%#{value}%") or ^dynamic)
      "starts_with" -> dynamic([{a, position}], ilike(field(a, ^field), ^"#{value}%") or ^dynamic)
      _ -> {:error, :comparator_not_supported, field: field, comparator: comparator, value: value}
    end
  end
end
