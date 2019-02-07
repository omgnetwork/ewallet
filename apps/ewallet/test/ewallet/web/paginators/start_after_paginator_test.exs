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

defmodule EWallet.Web.StartFromPaginatorTest do
  use EWallet.DBCase, async: true
  import Ecto.Query
  alias EWallet.Web.StartAfterPaginator
  alias EWallet.Web.Paginator
  alias EWalletDB.{Account, Repo}

  describe "EWallet.Web.Paginator.paginate_attrs/2" do
    test "returns :error if given `start_by` is not either a string or an atom" do
      result =
        StartAfterPaginator.paginate_attrs(Account, %{"per_page" => 10, "start_by" => 1}, [:id])

      assert {:error, :invalid_parameter, _} = result
    end

    test "returns :error if given `start_by` is not valid and missing `start_after` field" do
      result =
        StartAfterPaginator.paginate_attrs(Account, %{"per_page" => 10, "start_by" => "name"}, [
          :id
        ])

      assert {:error, :invalid_parameter, _} = result
    end

    test "returns :error if given `start_by` is not valid and `start_after` is nil" do
      result =
        StartAfterPaginator.paginate_attrs(
          Account,
          %{"per_page" => 10, "start_by" => "name", "start_after" => nil},
          [
            :id
          ]
        )

      assert {:error, :invalid_parameter, _} = result
    end

    test "returns :error if given `start_after` doesn't exist and `start_by` is valid" do
      result =
        StartAfterPaginator.paginate_attrs(
          Account,
          %{"start_after" => "acc_not_exist", "start_by" => "id", "per_page" => 10},
          [:id]
        )

      assert {:error, :unauthorized} = result
    end

    test "returns pagination if given `start_after` is nil and `start_by` is valid" do
      result =
        StartAfterPaginator.paginate_attrs(
          Account,
          %{"start_after" => nil, "start_by" => "id", "per_page" => 10},
          [:id]
        )

      %Paginator{data: _, pagination: pagination} = result
      assert pagination.start_after == nil
      assert pagination.start_by == "id"
      assert pagination.per_page == 10
    end

    test "returns pagination if given `start_after` is nil and `start_by` is nil" do
      result =
        StartAfterPaginator.paginate_attrs(
          Account,
          %{"start_after" => nil, "start_by" => nil, "per_page" => 10},
          [:id]
        )

      %Paginator{data: _, pagination: pagination} = result
      assert pagination.start_after == nil
      assert pagination.start_by == "id"
      assert pagination.per_page == 10
    end

    test "returns pagination if given `start_after` exists and `start_by` is valid" do
      ensure_num_records(Account, 2)

      record_id = from(a in Account, select: a.id, order_by: a.id, limit: 1)

      [record_id | _] = Repo.all(record_id)

      result =
        StartAfterPaginator.paginate_attrs(
          Account,
          %{"start_after" => record_id, "start_by" => "id", "per_page" => 10},
          [:id]
        )

      %Paginator{data: _, pagination: pagination} = result
      assert pagination.start_after == record_id
      assert pagination.start_by == "id"
      assert pagination.per_page == 10
      assert pagination.count == 1
    end

    test "returns pagination if given `start_after` exists and `start_by` is nil" do
      ensure_num_records(Account, 2)

      record_id = from(a in Account, select: a.id, order_by: a.id, limit: 1)

      [record_id | _] = Repo.all(record_id)

      result =
        StartAfterPaginator.paginate_attrs(
          Account,
          %{"start_after" => record_id, "start_by" => nil, "per_page" => 10},
          [:id]
        )

      %Paginator{data: _, pagination: pagination} = result
      assert pagination.start_after == record_id
      assert pagination.start_by == "id"
      assert pagination.per_page == 10
      assert pagination.count == 1
    end

    test "returns pagination if given `start_after` exist and `start_by` is :inserted_at" do
      ensure_num_records(Account, 2)

      iats = from(a in Account, select: a.inserted_at, order_by: a.inserted_at)

      [iat | _] =
        iats
        |> Repo.all()

      paginator =
        StartAfterPaginator.paginate_attrs(
          Account,
          %{"start_after" => iat, "start_by" => "inserted_at", "per_page" => 5},
          [:id, :inserted_at]
        )

      assert paginator.pagination.per_page == 5
      assert paginator.pagination.count == 1
    end
  end

  describe "EWallet.Web.StartAfterPaginator.get_query_offset/3" do
    test "returns offset if given `start_by`, `start_after`" do
      ensure_num_records(Account, 10)

      records = from(a in Account, select: a, order_by: a.id)

      [first | _] =
        records
        |> Repo.all()

      offset =
        StartAfterPaginator.get_query_offset(
          Account,
          %{"start_by" => "id", "start_after" => first.id},
          Repo
        )

      assert offset == 1
    end

    test "returns offset if given `start_by`, `start_after`, `sort_by`" do
      ensure_num_records(Account, 10)

      records = from(a in Account, select: a, order_by: a.name)

      [first | _] =
        records
        |> Repo.all()

      offset =
        StartAfterPaginator.get_query_offset(
          Account,
          %{"start_by" => "id", "start_after" => first.id, "sort_by" => "name"},
          Repo
        )

      assert offset == 1
    end

    test "returns offset 0 if the given `start_after` is nil" do
      ensure_num_records(Account, 10)

      offset =
        StartAfterPaginator.get_query_offset(
          Account,
          %{"start_after" => nil, "start_by" => "id"},
          Repo
        )

      assert offset == 0
    end
  end

  describe "EWallet.Web.StartAfterPaginator.paginate/3" do
    test "returns pagination data when query if given both `start_by` and `start_after` exist" do
      per_page = 10
      total_records = 5

      # Generate 10 accounts
      # Example: [%{id: "acc_1"}, %{id: "acc_2"}, ... , %{id: "acc_10"}]
      ensure_num_records(Account, 10)

      # Fetch last `total_records` elements from db
      # Example: [%{id: "acc_6"}, %{id: "acc_7"}, ... , %{id: "acc_10"}]
      records_id = from(a in Account, select: a.id, order_by: a.id)

      records_id =
        records_id
        |> Repo.all()
        # get last 5 records
        |> Enum.take(-total_records)

      # Example: ["acc_6" | ids]
      [first_id | ids] = records_id

      paginator =
        StartAfterPaginator.paginate(
          Account,
          %{
            "start_by" => "id",
            "start_after" => first_id,
            "per_page" => per_page
          }
        )

      # Collect id-mapped paginator.data
      actual_records_id =
        paginator.data
        |> Enum.map(fn %Account{id: id} -> id end)

      assert actual_records_id == ids

      assert paginator.pagination == %{
               per_page: per_page,
               is_last_page: true,
               count: total_records - 1,
               start_after: first_id,
               start_by: "id"
             }
    end

    test "returns records from the beginning if given start_after is nil" do
      per_page = 10

      # Generate 10 accounts
      # Example: [%{id: "acc_1"}, %{id: "acc_2"}, ... , %{id: "acc_10"}]
      ensure_num_records(Account, per_page)

      # Fetch last `total_records` elements from db
      # Example: [%{id: "acc_6"}, %{id: "acc_7"}, ... , %{id: "acc_10"}]
      records_id = from(a in Account, select: a.id, order_by: a.id)

      records_id =
        records_id
        |> Repo.all()

      paginator =
        StartAfterPaginator.paginate(
          Account,
          %{
            "start_by" => "id",
            "start_after" => {:ok, nil},
            "per_page" => per_page
          }
        )

      # Collect id-mapped paginator.data
      actual_records_id =
        paginator.data
        |> Enum.map(fn %Account{id: id} -> id end)

      assert actual_records_id == records_id

      assert paginator.pagination == %{
               per_page: per_page,
               is_last_page: true,
               count: per_page,
               start_after: nil,
               start_by: "id"
             }
    end

    test "returns :error if start_after doesn't exist" do
      total = 10
      per_page = 10
      ensure_num_records(Account, total)

      paginator =
        StartAfterPaginator.paginate(
          Account,
          %{"start_by" => "id", "start_after" => "1", "per_page" => per_page}
        )

      assert paginator === {:error, :unauthorized}
    end
  end
end
