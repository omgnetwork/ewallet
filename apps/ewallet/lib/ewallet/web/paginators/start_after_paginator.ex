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

defmodule EWallet.Web.StartAfterPaginator do
  @moduledoc """
  The Paginator allows querying of records by page. It takes in a query, break the query down,
  then selectively query only records that are within the given page's scope.
  """
  import Ecto.Query
  alias EWalletDB.Repo
  alias EWallet.Web.Paginator

  @doc """
  Paginate a query by attempting to extract `start_after`, `start_by` and `per_page`
  from the given map of attributes and returns a paginator.

  Note that this function is made to allow an easy passing of user inputs
  without the caller needing any knowledge of the pagination attributes
  (so long as the attribute keys don't conflict). Therefore this function
  expects attribute keys to be strings, not atoms.
  """
  @spec paginate_attrs(Ecto.Query.t() | Ecto.Queryable.t(), map(), Ecto.Repo.t()) ::
          %Paginator{} | {:error, :invalid_parameter, String.t()}
  def paginate_attrs(queryable, attrs, allowed_fields \\ [], repo \\ Repo)

  # Prevent non-string, non-atom `start_by`
  def paginate_attrs(_, %{"start_by" => start_by}, _, _)
      when not is_binary(start_by) and not is_atom(start_by) do
    {:error, :invalid_parameter, "`start_by` must be a string"}
  end

  def paginate_attrs(
        queryable,
        %{"start_after" => nil} = attrs,
        allowed_fields,
        repo
      ) do
    start_after = {:ok, nil}
    paginate_attrs(queryable, Map.put(attrs, "start_after", start_after), allowed_fields, repo)
  end

  def paginate_attrs(
        queryable,
        %{
          "start_by" => start_by,
          "start_after" => start_after,
          "per_page" => per_page
        },
        allowed_fields,
        repo
      ) do
    start_by = get_start_by(start_by)

    case start_by in allowed_fields do
      true ->
        paginate(
          queryable,
          %{
            "per_page" => per_page,
            "start_by" => start_by,
            "start_after" => start_after
          },
          repo
        )

      _ ->
        available_fields = inspect(allowed_fields)

        msg =
          "start_by: `#{start_by}` is not allowed. The available fields are: #{available_fields}"

        {:error, :invalid_parameter, msg}
    end
  end

  def paginate_attrs(queryable, %{"start_after" => _, "per_page" => per_page} = attrs, [field | _], repo) do
    # Set default value of `start_by` to the first element of allowed_fields
    attrs =
      attrs
      |> Map.put("start_by", field)
      |> Map.put("per_page", per_page)

    paginate_attrs(queryable, attrs, [field], repo)
  end

  @doc """
  Paginate a query using the given `page` and `per_page` and returns a paginator.
  If a query has `start_after`, then returns a paginator with all records after the specify `start_after`.
  """
  def paginate(queryable, attrs, repo \\ Repo)

  def paginate(
        queryable,
        %{
          "start_by" => start_by,
          "start_after" => {:ok, start_after},
          "per_page" => per_page
        },
        repo
      ) do
    {records, more_page} =
      queryable
      |> get_query_start_after(%{"start_by" => start_by, "start_after" => start_after})
      # effect only when `sort_by` doesn't specify.
      |> order_by([q], field(q, ^start_by))
      |> Paginator.fetch(
        %{"start_after" => start_after, "page" => 1, "per_page" => per_page},
        repo
      )

    pagination = %{
      current_page: 1,
      per_page: per_page,
      start_by: Atom.to_string(start_by),
      start_after: start_after,
      is_first_page: true,
      # It's the last page if there are no more records
      is_last_page: !more_page,
      count: length(records)
    }

    %Paginator{data: records, pagination: pagination}
  end

  def paginate(_, %{"start_after" => {:error}}, _), do: {:error, :unauthorized}

  def paginate(
        queryable,
        %{
          "start_by" => start_by,
          "start_after" => start_after,
          "per_page" => per_page
        },
        repo
      ) do
    # Verify if the given `start_after` exist to prevent unexpected result.
    target = Map.put(%{}, start_by, start_after)
    exist = repo.get_by(queryable, target) != nil

    start_after =
      if exist do
        {:ok, start_after}
      else
        {:error}
      end

    paginate(
      queryable,
      %{
        "start_by" => start_by,
        "start_after" => start_after,
        "per_page" => per_page
      },
      repo
    )
  end

  defp get_start_by(start_by) do
    case start_by do
      s when is_binary(s) -> String.to_atom(s)
      _ -> start_by
    end
  end

  defp get_query_start_after(queryable, %{"start_after" => start_after, "start_by" => start_by}) do
    case start_after do
      s when is_nil(s) or s === "" ->
        queryable

      _ ->
        queryable
        |> where([q], field(q, ^start_by) > ^start_after)
    end
  end
end
