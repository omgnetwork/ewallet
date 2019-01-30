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
  The StartAfterPaginator allows querying of records by specified `start_after` and `start_by`.
  They take in a query, break the query down,
  then selectively query only records that are after the given `start_after`'s scope.

  If the `start_after` is nil, then return records from the beginning.

  For example:

  ```
  StartAfterPaginator.paginate_attrs(
    Account,
    %{"start_after" => "acc_3", "start_by" => "id", "per_page" => 10},
    [:id]
  )
  ```

  Let's say we have 10 accounts with ids:
  ["acc_1", "acc_2", "acc_3", ... , "acc_10"]

  The code above return a pagination with accounts:
  ["acc_4", "acc_5", "acc_6", ... ,"acc_10"]

  Note that an account with id "acc_3" is not included because the query range is exclusive.

  However, query accounts from the beginning is possible by specifying `start_after` to nil:

  ```
  StartAfterPaginator.paginate_attrs(
    Account,
    %{"start_after" => nil, "start_by" => "id", "per_page" => 10},
    [:id]
  )
  ```

  Return accounts:
  ["acc_1", "acc_2", "acc_3", ... ,"acc_10"]
  """
  import Ecto.Query
  alias EWalletDB.Repo
  alias EWallet.Web.Paginator

  @doc """
  Paginate a query by attempting to extract `start_after`, `start_by` and `per_page`
  from the given map of attributes and returns a paginator.
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
        %{"start_after" => nil, "start_by" => start_by} = attrs,
        allowed_fields,
        repo
      )
      when start_by != nil and is_atom(start_by) do
    attrs = Map.put(attrs, "start_after", {:ok, nil})
    paginate_attrs(queryable, attrs, allowed_fields, repo)
  end

  def paginate_attrs(
        queryable,
        %{
          "start_after" => start_after,
          "start_by" => start_by,
          "per_page" => per_page
        },
        allowed_fields,
        repo
      )
      when start_by != nil and is_atom(start_by) do
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

  # Resolve `start_by` by set default value or parse string
  def paginate_attrs(queryable, %{"start_after" => _} = attrs, allowed_fields, repo) do
    attrs = get_start_by_attrs(attrs, allowed_fields)
    paginate_attrs(queryable, attrs, allowed_fields, repo)
  end

  # Resolve `start_after` by set default value to nil.
  def paginate_attrs(queryable, attrs, allowed_fields, repo) do
    attrs = Map.put(attrs, "start_after", nil)
    paginate_attrs(queryable, attrs, allowed_fields, repo)
  end

  @doc """
  Paginate a query using the given `page` and `per_page` and returns a paginator.
  If a query has `start_after`, then returns a paginator with all records after the specify `start_after`.
  """
  def paginate(queryable, attrs, repo \\ Repo)

  # Returns :error if the record with `start_after` value is not found.
  def paginate(_, %{"start_after" => {:error}}, _), do: {:error, :unauthorized}

  # Query and returns `Paginator`
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
      # effect only when `sort_by` doesn't specify.
      |> get_queryable_start_after(%{"start_after" => start_after, "start_by" => start_by})
      |> order_by([q], field(q, ^start_by))
      |> Paginator.fetch(
        %{"page" => 0, "per_page" => per_page},
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

  # Checking if the `start_after` value exist in the db.
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
    condition = Map.put(%{}, start_by, start_after)

    # To ensure there's no another where condition e.g. `search_term`.
    pure_queryable =
      queryable
      |> exclude(:where)

    start_after =
      if repo.get_by(pure_queryable, condition) != nil do
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

  defp get_start_by_attrs(attrs, [field | _allowed_fields]) do
    case Map.get(attrs, "start_by") do
      nil -> Map.put(attrs, "start_by", field)
      start_by when is_binary(start_by) -> Map.put(attrs, "start_by", String.to_atom(start_by))
      _ -> attrs
    end
  end

  # Query records from the beginning if `start_after` is null or empty,
  # Otherwise querying after specified `start_after` by `start_by` field.
  defp get_queryable_start_after(queryable, %{
         "start_after" => start_after,
         "start_by" => start_by
       }) do
    case start_after do
      s when is_nil(s) or s === "" ->
        queryable

      _ ->
        queryable
        |> where([q], field(q, ^start_by) > ^start_after)
    end
  end
end
