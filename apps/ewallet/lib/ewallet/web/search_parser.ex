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
    terms
    |> Enum.reduce(false, fn {field, value}, dynamic ->
      field =
        field
        |> map_field(mapping)
        |> allowed?(fields)

      build_and_search_query(dynamic, field, value)
    end)
    |> handle_dynamic_return(queryable)
  end

  def to_query(queryable, %{"search_term" => term}, fields, _mapping) when term != nil do
    fields
    |> Enum.reduce(false, fn field, dynamic ->
      build_or_search_query(dynamic, field, term)
    end)
    |> handle_dynamic_return(queryable)
  end

  def to_query(queryable, _, _, _), do: queryable

  defp handle_dynamic_return(false, queryable), do: queryable

  defp handle_dynamic_return(dynamic, queryable) do
    from(queryable, where: ^dynamic)
  end

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

  defp build_or_search_query(dynamic, _field, nil), do: dynamic
  defp build_or_search_query(dynamic, nil, _value), do: dynamic

  defp build_or_search_query(false, {field, :uuid}, term) do
    dynamic([q], ilike(fragment("?::text", field(q, ^field)), ^"%#{term}%"))
  end

  defp build_or_search_query(dynamic, {field, :uuid}, term) do
    dynamic([q], ilike(fragment("?::text", field(q, ^field)), ^"%#{term}%") or ^dynamic)
  end

  defp build_or_search_query(false, field, term) do
    dynamic([q], ilike(field(q, ^field), ^"%#{term}%"))
  end

  defp build_or_search_query(dynamic, field, term) do
    dynamic([q], ilike(field(q, ^field), ^"%#{term}%") or ^dynamic)
  end

  defp build_and_search_query(dynamic, _field, nil), do: dynamic
  defp build_and_search_query(dynamic, nil, _value), do: dynamic

  defp build_and_search_query(false, {field, :uuid}, term) do
    dynamic([q], ilike(fragment("?::text", field(q, ^field)), ^"%#{term}%"))
  end

  defp build_and_search_query(dynamic, {field, :uuid}, term) do
    dynamic([q], ilike(fragment("?::text", field(q, ^field)), ^"%#{term}%") and ^dynamic)
  end

  defp build_and_search_query(false, field, term) do
    dynamic([q], ilike(field(q, ^field), ^"%#{term}%"))
  end

  defp build_and_search_query(dynamic, field, term) do
    dynamic([q], ilike(field(q, ^field), ^"%#{term}%") and ^dynamic)
  end
end
