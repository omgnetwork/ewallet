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

defmodule EWallet.Web.Paginator do
  @moduledoc """
  The Paginator allows querying of records by `page` or `start_after`.
  If `start_after` was specified, then delegate the parameters to `StartAfterPaginator`.
  Otherwise delegate the parameters to `PagePaginator`.
  """
  import Ecto.Query
  alias EWalletDB.Repo
  alias EWallet.Web.PagePaginator
  alias EWallet.Web.StartAfterPaginator

  @default_per_page 10
  @default_max_per_page 100

  # TODO Change the pagination structure to support `start_after` and unsupport `page`.
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
  def paginate_attrs(queryable, attrs, allowed_fields \\ [], repo \\ Repo)

  # TODO Remove this function to unsupport `page`
  # Prevent `page` to be combined with `start_after`
  def paginate_attrs(_, %{"page" => _, "start_after" => _}, _, _) do
    {:error, :invalid_parameter, "`page` cannot be used with `start_after`"}
  end

  # Prevent non-negative, non-zero integer `per_page`
  def paginate_attrs(_, %{"per_page" => per_page}, _, _)
      when is_integer(per_page) and per_page < 1 do
    {:error, :invalid_parameter, "`per_page` must be non-negative, non-zero integer"}
  end

  # TODO Remove this function to unsupport `page`
  # Convert `per_page` type from string to integer.
  def paginate_attrs(queryable, %{"per_page" => per_page} = attrs, allowed_fields, repo)
      when is_binary(per_page) do
    case parse_string_param(attrs, "per_page", per_page) do
      {:error, code, description} -> {:error, code, description}
      attrs -> paginate_attrs(queryable, attrs, allowed_fields, repo)
    end
  end

  # TODO Remove this function to unsupport `page`
  # Convert `page` type from string to integer
  def paginate_attrs(queryable, %{"page" => page} = attrs, allowed_fields, repo)
      when is_binary(page) do
    case parse_string_param(attrs, "page", page) do
      {:error, code, description} -> {:error, code, description}
      attrs -> paginate_attrs(queryable, attrs, allowed_fields, repo)
    end
  end

  # TODO Remove this function to unsupport `page`
  # Delegate `attrs` to the `PagePaginator`
  def paginate_attrs(queryable, %{"page" => _} = attrs, _, repo) do
    per_page = get_per_page(attrs)
    attrs = Map.put(attrs, "per_page", per_page)
    PagePaginator.paginate_attrs(queryable, attrs, repo)
  end

  # Delegate `attrs` to the `StartAfterPaginator`
  def paginate_attrs(queryable, %{"start_after" => _} = attrs, allowed_fields, repo) do
    per_page = get_per_page(attrs)
    attrs = Map.put(attrs, "per_page", per_page)
    StartAfterPaginator.paginate_attrs(queryable, attrs, allowed_fields, repo)
  end

  # Delegate `attrs` to the `StartAfterPaginator`
  def paginate_attrs(queryable, %{"start_by" => _} = attrs, allowed_fields, repo) do
    per_page = get_per_page(attrs)
    attrs = Map.put(attrs, "per_page", per_page)
    StartAfterPaginator.paginate_attrs(queryable, attrs, allowed_fields, repo)
  end

  # Default pagination behavior (Delegate to PagePaginator)
  def paginate_attrs(queryable, attrs, _, repo) do
    per_page = get_per_page(attrs)
    attrs = Map.put(attrs, "per_page", per_page)

    # TODO `StartAfterPaginator` to use `start_after` as a default behavior.
    PagePaginator.paginate_attrs(queryable, attrs, repo)
  end

  @doc """
  Paginate a query by explicitly specifying `page` and `per_page`
  and returns a tuple of records and a flag whether there are more pages.
  """
  def fetch(queryable, %{"page" => page, "per_page" => per_page}, repo \\ Repo) do
    # + 1 to see if it is the last page yet
    limit = per_page + 1

    records =
      queryable
      |> get_query_offset(%{"page" => page, "per_page" => per_page})
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

  # Returns the per_page number or default, but never greater than the system's defined limit
  defp get_per_page(attrs) do
    per_page =
      attrs
      |> Map.get("per_page", @default_per_page)

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

  # Try to parse the given string pagination parameter.
  defp parse_string_param(attrs, name, value) do
    case Integer.parse(value, 10) do
      {page, ""} ->
        Map.put(attrs, name, page)

      :error ->
        {:error, :invalid_parameter, "`#{name}` must be non-negative integer"}
    end
  end
end
