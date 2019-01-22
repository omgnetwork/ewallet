# Copyright 2018-2019 OmiseGO Pte Ltd
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

defmodule EWallet.Web.Paginator do
  @moduledoc """
  The Paginator allows querying of records by page. It takes in a query, break the query down,
  then selectively query only records that are within the given page's scope.
  """
  import Ecto.Query
  alias EWalletDB.Repo

  @default_page 1
  @default_per_page 10
  @default_max_per_page 100

  defstruct data: [],
            pagination: %{
              per_page: nil,
              current_page: nil,
              is_first_page: nil,
              is_last_page: nil,
              count: nil
            }

  @doc """
  Paginate a query by attempting to extract `page` and `per_page`
  from the given map of attributes and returns a paginator.

  Note that this function is made to allow an easy passing of user inputs
  without the caller needing any knowledge of the pagination attributes
  (so long as the attribute keys don't conflict). Therefore this function
  expects attribute keys to be strings, not atoms.
  """
  @spec paginate_attrs(Ecto.Query.t() | Ecto.Queryable.t(), map(), Ecto.Repo.t()) ::
          %__MODULE__{} | {:error, :invalid_parameter, String.t()}
  def paginate_attrs(queryable, attrs, allowed_page_record_fields \\ [], repo \\ Repo)

  def paginate_attrs(queryable, %{"page" => page} = attrs, allowed_page_record_fields, repo)
      when not is_integer(page) do
    parse_string_param(queryable, attrs, "page", page, allowed_page_record_fields, repo)
  end

  def paginate_attrs(
        queryable,
        %{"per_page" => per_page} = attrs,
        allowed_page_record_fields,
        repo
      )
      when not is_integer(per_page) do
    parse_string_param(queryable, attrs, "per_page", per_page, allowed_page_record_fields, repo)
  end

  def paginate_attrs(_, %{"page" => _, "page_record_value" => _}, _, _) do
    {:error, :invalid_parameter, "`page` cannot be used with `page_record_value`"}
  end

  def paginate_attrs(
        queryable,
        %{"page_record_field" => page_record_field, "page_record_value" => page_record_value} =
          attrs,
        allowed_page_record_fields,
        repo
      )
      when is_bitstring(page_record_value) and is_bitstring(page_record_field) do
    per_page = get_per_page(attrs)
    page_record_field = String.to_atom(page_record_field)

    paginate_attrs(
      queryable,
      %{
        "per_page" => per_page,
        "page_record_field" => page_record_field,
        "page_record_value" => page_record_value
      },
      allowed_page_record_fields,
      repo
    )
  end

  def paginate_attrs(
        queryable,
        %{"page_record_field" => page_record_field, "page_record_value" => page_record_value} =
          attrs,
        allowed_page_record_fields,
        repo
      )
      when is_bitstring(page_record_value) and is_atom(page_record_field) do
    case page_record_field in allowed_page_record_fields do
      true ->
        paginate(queryable, attrs, repo)

      _ ->
        {:error, :invalid_parameter,
         "page_record_field: `#{page_record_field}` is not allowed. The available fields are: #{
           inspect(allowed_page_record_fields)
         }"}
    end
  end

  def paginate_attrs(
        queryable,
        %{"page_record_value" => page_record_value} = attrs,
        allowed_page_record_fields,
        repo
      )
      when is_bitstring(page_record_value) do
    # Set default value of `page_record_field` to the first element in `allowed_page_record_fields`
    page_record_field = Enum.at(allowed_page_record_fields, 0) |> Atom.to_string()
    attrs = Map.put(attrs, "page_record_field", page_record_field)

    paginate_attrs(queryable, attrs, allowed_page_record_fields, repo)
  end

  def paginate_attrs(_, %{"page" => page}, _, _) when is_integer(page) and page < 0 do
    {:error, :invalid_parameter, "`page` must be non-negative integer"}
  end

  def paginate_attrs(_, %{"per_page" => per_page}, _, _)
      when is_integer(per_page) and per_page < 1 do
    {:error, :invalid_parameter, "`per_page` must be non-negative, non-zero integer"}
  end

  def paginate_attrs(_, %{"page_record_field" => page_record_value}, _, _)
      when not is_bitstring(page_record_value) do
    {:error, :invalid_parameter, "`page_record_field` must be a string"}
  end

  def paginate_attrs(_, %{"page_record_value" => page_record_value}, _, _)
      when not is_bitstring(page_record_value) do
    {:error, :invalid_parameter, "`page_record_value` must be a string"}
  end

  def paginate_attrs(queryable, attrs, _, repo) do
    page = Map.get(attrs, "page", @default_page)
    per_page = get_per_page(attrs)

    paginate(queryable, %{"page" => page, "per_page" => per_page}, repo)
  end

  # Try to parse the given string pagination parameter.
  defp parse_string_param(queryable, attrs, name, value, allowed_page_record_fields, repo) do
    case Integer.parse(value, 10) do
      {page, ""} ->
        attrs = Map.put(attrs, name, page)
        paginate_attrs(queryable, attrs, allowed_page_record_fields, repo)

      :error ->
        {:error, :invalid_parameter, "`#{name}` must be non-negative integer"}
    end
  end

  # Returns the per_page number or default, but never greater than the system's defined limit
  defp get_per_page(attrs) do
    per_page = Map.get(attrs, "per_page", @default_per_page)

    max_per_page =
      case Application.get_env(:ewallet, :max_per_page) do
        nil -> @default_max_per_page
        "" -> @default_max_per_page
        value when is_binary(value) -> String.to_integer(value)
        value when is_integer(value) -> value
      end

    case per_page do
      n when n > max_per_page -> max_per_page
      _ -> per_page
    end
  end

  @doc """
  Paginate a query using the given `page` and `per_page` and returns a paginator.
  If a query has `page_record_value`, then returns a paginator with all records after the specify `page_record_value`.
  """
  def paginate(queryable, attrs, repo \\ Repo)

  def paginate(queryable, %{"page" => _, "per_page" => _} = attrs, repo) do
    {records, more_page} = fetch(queryable, attrs, repo)

    # Return pagination result
    paginate(attrs, more_page, records)
  end

  def paginate(
        queryable,
        %{
          "page_record_field" => page_record_field,
          "page_record_value" => page_record_value,
          "per_page" => per_page
        } = attrs,
        repo
      ) do
    # Verify if the given `page_record_value` exist to prevent unexpected result.
    if repo.get_by(queryable, id: page_record_value) == nil do
      {:error, :invalid_parameter,
       "The given page_record_value `#{page_record_value}` does not exist on the page_record_field `#{
         page_record_field
       }`"}
    else
      page = Map.get(attrs, "page", @default_page)

      {records, more_page} =
        queryable
        |> where([q], field(q, ^page_record_field) >= ^page_record_value)
        # effect only when `sort_by` doesn't specify.
        |> order_by([q], field(q, ^page_record_field))
        |> fetch(
          %{"page_record_value" => page_record_value, "page" => page, "per_page" => per_page},
          repo
        )

      # Return pagination result
      paginate(%{"page" => page, "per_page" => per_page}, more_page, records)
    end
  end

  def paginate(%{"page" => page, "per_page" => per_page}, more_page, records)
      when is_list(records) do
    pagination = %{
      per_page: per_page,
      current_page: page,
      is_first_page: page <= 1,
      # It's the last page if there are no more records
      is_last_page: !more_page,
      count: length(records)
    }

    %__MODULE__{data: records, pagination: pagination}
  end

  @doc """
  Paginate a query by explicitly specifying `page` and `per_page`
  and returns a tuple of records and a flag whether there are more pages.
  """
  def fetch(queryable, attrs, repo \\ Repo) do
    %{"per_page" => per_page} = attrs

    # + 1 to see if it is the last page yet
    limit = per_page + 1

    records =
      queryable
      |> get_query_offset(attrs)
      |> limit(^limit)
      |> repo.all()

    # If an extra record is found, remove last one and inform there is more.
    case Enum.count(records) do
      n when n > per_page ->
        {List.delete_at(records, -1), true}

      _ ->
        {records, false}
    end
  end

  defp get_query_offset(queryable, %{"page" => page, "per_page" => per_page}) do
    offset =
      case page do
        n when n > 0 -> (page - 1) * per_page
        _ -> 0
      end

    queryable
    |> offset(^offset)
  end
end
