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
  `["acc_1", "acc_2", "acc_3", ... , "acc_10"]`

  The code above return a pagination with accounts:
  `["acc_4", "acc_5", "acc_6", ... ,"acc_10"]`

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
  `["acc_1", "acc_2", "acc_3", ... ,"acc_10"]`
  """
  import Ecto.Query
  require Logger
  alias EWalletDB.Repo
  alias EWallet.Web.Paginator

  @doc """
  Paginate a query by attempting to extract `start_after`, `start_by` and `per_page`
  from the given map of attributes and returns a paginator.
  """
  @spec paginate_attrs(Ecto.Query.t() | Ecto.Queryable.t(), map(), [], Ecto.Repo.t(), map()) ::
          %Paginator{} | {:error, :invalid_parameter, String.t()}
  def paginate_attrs(
        queryable,
        attrs,
        allowed_fields \\ [],
        repo \\ Repo,
        default_mapped_fields \\ %{}
      )

  # Prevent non-string, non-atom `start_by`
  def paginate_attrs(_, %{"start_by" => start_by}, _, _, _)
      when not is_binary(start_by) and not is_atom(start_by) do
    {:error, :invalid_parameter, "`start_by` must be a string"}
  end

  def paginate_attrs(
        queryable,
        attrs,
        allowed_fields,
        repo,
        default_mapped_fields
      ) do
    default_field = Atom.to_string(hd(allowed_fields))

    sort_by = map_atom_attr(attrs, "sort_by", default_field, default_mapped_fields)
    start_by = map_atom_attr(attrs, "start_by", default_field, default_mapped_fields)

    case is_allowed_start_by(start_by, allowed_fields) do
      true ->
        attrs =
          attrs
          |> Map.put("sort_by", sort_by)
          |> Map.put("start_by", start_by)

        paginate(queryable, attrs, repo)

      _ ->
        available_fields =
          allowed_fields
          |> Enum.map(&Atom.to_string/1)
          |> Enum.join(", ")

        start_by = Atom.to_string(start_by)

        msg =
          "start_by: `#{start_by}` is not allowed. The available fields are: [#{available_fields}]"

        {:error, :invalid_parameter, msg}
    end
  end

  def map_atom_attr(attrs, key, default, mapping) do
    attrs[key]
    |> map_default(default)
    |> map_field(mapping)
    |> map_atom(default)
  end

  defp map_default(original, default) do
    case original do
      nil -> default
      any -> any
    end
  end

  defp map_field(original, mapping) do
    case mapping[original] do
      nil -> original
      mapped -> mapped
    end
  end

  defp map_atom(original, default) do
    String.to_existing_atom(original)
  rescue
    ArgumentError -> default
  end

  @doc """
  Paginate a query using the given `start_after` and `start_by`.
  Returns a paginator with all records after the specify `start_after` record.
  """
  def paginate(queryable, attrs, repo \\ Repo)

  # Query and returns `Paginator`
  def paginate(
        queryable,
        %{
          "start_by" => start_by,
          "start_after" => {:ok, start_after},
          "per_page" => per_page
        } = attrs,
        repo
      ) do
    attrs = Map.put(attrs, "start_after", start_after)

    {records, more_page} =
      queryable
      |> get_queryable_start_after(attrs)
      |> get_queryable_order_by(attrs)
      |> fetch(per_page, repo)

    pagination = %{
      per_page: per_page,
      start_by: Atom.to_string(start_by),
      start_after: start_after,
      # It's the last page if there are no more records
      is_last_page: !more_page,
      count: length(records)
    }

    %Paginator{data: records, pagination: pagination}
  end

  def paginate(queryable, %{"start_after" => nil} = attrs, repo),
    do: paginate(queryable, %{attrs | "start_after" => {:ok, nil}}, repo)

  # Checking if the `start_after` value exist in the db.
  def paginate(
        queryable,
        %{
          "start_by" => start_by,
          "start_after" => start_after,
          "per_page" => _
        } = attrs,
        repo
      ) do
    # Verify if the given `start_after` exist to prevent unexpected result.
    condition =
      build_start_after_condition(%{"start_by" => start_by, "start_after" => start_after})

    pure_queryable = exclude(queryable, :where)

    record =
      try do
        repo.get_by(pure_queryable, condition)
      rescue
        Ecto.Query.CastError -> build_error(:start_after_cast_error, start_after, start_by)
        error -> build_error(:unknown_db_error, error)
      end

    case record do
      {:error, _, _} -> record
      # Returns error if the record with `start_after` value is not found.
      nil -> {:error, :unauthorized}
      # Record with `start_after` value is found, query the result.
      _ -> paginate(queryable, %{attrs | "start_after" => {:ok, start_after}}, repo)
    end
  end

  defp build_error(:start_after_cast_error, start_after, start_by) do
    msg =
      ""
      |> Kernel.<>("Invalid `start_after` or `start_by` provided. ")
      |> Kernel.<>("Given `#{start_after}` cannot be casted to given `#{start_by}`.")

    {:error, :invalid_parameter, msg}
  end

  defp build_error(:unknown_db_error, error) do
    # This event should not happen.
    # We will need to handle more if we encounter this error.
    Logger.error("An unknown error occurred during pagination. Error: #{inspect(error)}")
    {:error, :unknown_error, "An unknown error occured on the database."}
  end

  defp fetch(queryable, per_page, repo) do
    limit = per_page + 1

    records =
      queryable
      |> limit(^limit)
      |> repo.all()

    case Enum.count(records) do
      n when n > per_page ->
        {List.delete_at(records, -1), true}

      _ ->
        {records, false}
    end
  end

  def is_allowed_start_by(start_by, allowed_fields) do
    start_by in allowed_fields
  end

  def build_start_after_condition(%{"start_by" => start_by, "start_after" => start_after}) do
    Map.put(%{}, start_by, start_after)
  end

  # Query records from the beginning if `start_after` is null or empty,
  # Otherwise querying after specified `start_after` by `start_by` field.
  defp get_queryable_start_after(
         queryable,
         %{
           "start_after" => _,
           "start_by" => _
         } = attrs
       ) do
    offset = get_offset(queryable, attrs)

    queryable
    |> offset(^offset)
  end

  defp get_offset(_, %{"start_after" => nil}), do: 0

  defp get_offset(
         queryable,
         %{
           "start_after" => start_after,
           "start_by" => start_by,
           "sort_by" => sort_by,
           "sort_dir" => sort_dir
         }
       ) do
    offset_queryable =
      queryable
      |> exclude(:preload)
      |> exclude(:distinct)
      |> exclude(:select)
      |> get_offset_queryable(%{
        "start_by" => start_by,
        "sort_by" => sort_by,
        "sort_dir" => sort_dir
      })

    queryable = from(q in subquery(offset_queryable))

    result =
      queryable
      |> select([q], q.offset)
      |> where([q], q.start_by == ^start_after)
      |> Repo.all()

    parse_get_offset(result)
  end

  defp get_offset(queryable, %{"start_after" => start_after, "start_by" => start_by} = attrs) do
    sort_dir = Map.get(attrs, "sort_dir", "asc")
    sort_by = Map.get(attrs, "sort_by", start_by)

    get_offset(
      queryable,
      %{
        "start_after" => start_after,
        "start_by" => start_by,
        "sort_by" => sort_by,
        "sort_dir" => sort_dir
      }
    )
  end

  defp parse_get_offset([]), do: 0

  defp parse_get_offset([offset]), do: offset

  defp get_offset_queryable(queryable, %{
         "start_by" => start_by,
         "sort_by" => sort_by,
         "sort_dir" => "desc"
       }) do
    queryable
    |> select([a], %{
      start_by: field(a, ^start_by),
      offset: fragment("ROW_NUMBER() OVER (ORDER BY ? DESC)", field(a, ^sort_by))
    })
  end

  defp get_offset_queryable(queryable, %{"start_by" => start_by, "sort_by" => sort_by}) do
    queryable
    |> select([a], %{
      start_by: field(a, ^start_by),
      offset: fragment("ROW_NUMBER() OVER (ORDER BY ? ASC)", field(a, ^sort_by))
    })
  end

  defp get_queryable_order_by(queryable, %{"sort_dir" => "desc", "sort_by" => sort_by}) do
    order_by(queryable, desc: ^sort_by)
  end

  defp get_queryable_order_by(queryable, %{"sort_by" => sort_by}) do
    order_by(queryable, asc: ^sort_by)
  end
end
