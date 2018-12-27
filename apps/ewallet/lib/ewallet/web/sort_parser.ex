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

defmodule EWallet.Web.SortParser do
  @moduledoc """
  This module allows parsing of arbitrary attributes into a sorted query.
  It takes in a request's attributes, parses only the attributes needed for sorting,
  then builds those attributes into a sorted query on top of the given `Ecto.Queryable`.
  """
  import Ecto.Query

  @doc """
  Parses sorting attributes and appends the resulting queries into the given queryable.
  """
  @spec to_query(Ecto.Query.t(), map, list) :: {Ecto.Query.t()}
  def to_query(queryable, attrs, fields, mapped_fields \\ %{}) do
    field = get_sort_field(attrs, fields, mapped_fields)
    direction = get_sort_direction(attrs)

    build_sort_query(queryable, field, direction)
  end

  defp get_sort_field(%{"sort_by" => field}, allowed_fields, mapped_fields)
       when is_binary(field) and byte_size(field) > 0 and is_list(allowed_fields) and
              is_map(mapped_fields) do
    # Defaults back to the original field name
    field =
      mapped_fields
      |> Map.get(field, field)
      |> String.to_atom()

    if Enum.member?(allowed_fields, field), do: field, else: nil
  end

  defp get_sort_field(_, _, _), do: nil

  defp get_sort_direction(%{"sort_dir" => "asc"}), do: :asc
  defp get_sort_direction(%{"sort_dir" => "desc"}), do: :desc
  defp get_sort_direction(_attrs), do: nil

  def build_sort_query(queryable, field, direction)
      when is_atom(field) and not is_nil(field) and is_atom(direction) and not is_nil(direction) do
    order_by(queryable, {^direction, ^field})
  end

  def build_sort_query(queryable, _, _), do: queryable
end
