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

defmodule EWallet.Web.PagePaginator do
  @moduledoc """
  The Paginator allows querying of records by page. It takes in a query, break the query down,
  then selectively query only records that are within the given page's scope.
  """
  alias EWalletDB.Repo
  alias EWallet.Web.Paginator

  @default_page 1

  @doc """
  Paginate a query by attempting to extract `page` and `per_page`
  from the given map of attributes and returns a paginator.

  Note that this function is made to allow an easy passing of user inputs
  without the caller needing any knowledge of the pagination attributes
  (so long as the attribute keys don't conflict). Therefore this function
  expects attribute keys to be strings, not atoms.
  """
  @spec paginate_attrs(Ecto.Query.t() | Ecto.Queryable.t(), map(), Ecto.Repo.t()) ::
          %Paginator{} | {:error, :invalid_parameter, String.t()}
  def paginate_attrs(queryable, attrs, allowed_fields \\ [], repo \\ Repo)

  # Prevent negative-integer `page`.
  def paginate_attrs(_, %{"page" => page}, _, _) when is_integer(page) and page < 0 do
    {:error, :invalid_parameter, "`page` must be non-negative integer"}
  end

  def paginate_attrs(queryable, %{"per_page" => per_page} = attrs, _, repo) do
    # Set default param for `page` and `per_page`
    page = Map.get(attrs, "page", @default_page)

    # Put to the existing attrs
    attrs =
      attrs
      |> Map.put("per_page", per_page)
      |> Map.put("page", page)

    paginate(queryable, attrs, repo)
  end

  @doc """
  Paginate a query using the given `page` and `per_page` and returns a paginator.
  If a query has `start_after`, then returns a paginator with all records after the specify `start_after`.
  """
  def paginate(queryable, %{"page" => page, "per_page" => per_page} = attrs, repo \\ Repo) do
    {records, more_page} = Paginator.fetch(queryable, attrs, repo)

    # Return pagination result
    pagination = %{
      per_page: per_page,
      current_page: page,
      is_first_page: page <= 1,
      # It's the last page if there are no more records
      is_last_page: !more_page,
      count: length(records)
    }

    %Paginator{data: records, pagination: pagination}
  end
end
