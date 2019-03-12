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

defmodule EWallet.Web.StartFromPaginatorTest do
  use EWallet.DBCase, async: true
  import Ecto.Query
  alias EWallet.Web.StartAfterPaginator
  alias EWallet.Web.Paginator
  alias EWalletDB.{Account, Repo}

  @default_mapped_fields %{"created_at" => "inserted_at"}
  @default_allowed_fields [:id, :inserted_at, :updated_at]

  describe "EWallet.Web.StartAfterPaginator.paginate_attrs/5" do
    test "returns :error if given `start_by` is not either a string or an atom" do
      attrs = %{"per_page" => 10, "start_by" => 1}

      result = StartAfterPaginator.paginate_attrs(Account, attrs, [:id])

      assert {:error, :invalid_parameter, "`start_by` must be a string"} = result
    end

    test "returns :error if given `start_by` is not valid and missing `start_after` field" do
      attrs = %{"per_page" => 10, "start_by" => "name"}

      result = StartAfterPaginator.paginate_attrs(Account, attrs, [:id])

      assert {:error, :invalid_parameter,
              "start_by: `name` is not allowed. The available fields are: [id]"} = result
    end

    test "returns :error if given `start_by` is not valid and `start_after` is nil" do
      attrs = %{"per_page" => 10, "start_by" => "name", "start_after" => nil}

      result = StartAfterPaginator.paginate_attrs(Account, attrs, [:id])

      assert {:error, :invalid_parameter,
              "start_by: `name` is not allowed. The available fields are: [id]"} = result
    end

    test "returns :error if given `start_after` doesn't exist and `start_by` is valid" do
      attrs = %{"start_after" => "acc_not_exist", "start_by" => "id", "per_page" => 10}

      result = StartAfterPaginator.paginate_attrs(Account, attrs, [:id])

      assert {:error, :unauthorized} = result
    end

    test "returns pagination if given `start_after` is nil and `start_by` is valid" do
      attrs = %{"start_after" => nil, "start_by" => "id", "per_page" => 10}

      result = StartAfterPaginator.paginate_attrs(Account, attrs, [:id])

      %Paginator{data: _, pagination: pagination} = result
      assert pagination.start_after == nil
      assert pagination.start_by == "id"
      assert pagination.per_page == 10
    end

    test "returns pagination if given `start_after` is nil and `start_by` is nil" do
      attrs = %{"start_after" => nil, "start_by" => nil, "per_page" => 10}

      result = StartAfterPaginator.paginate_attrs(Account, attrs, [:id])

      %Paginator{data: _, pagination: pagination} = result
      assert pagination.start_after == nil
      assert pagination.start_by == "id"
      assert pagination.per_page == 10
    end

    test "returns pagination if given `start_after` exists and `start_by` is valid" do
      ensure_num_records(Account, 2)

      record_id = from(a in Account, select: a.id, order_by: a.id, limit: 1)

      [record_id | _] = Repo.all(record_id)

      attrs = %{"start_after" => record_id, "start_by" => "id", "per_page" => 10}

      result = StartAfterPaginator.paginate_attrs(Account, attrs, [:id])

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

      attrs = %{"start_after" => record_id, "start_by" => nil, "per_page" => 10}

      result = StartAfterPaginator.paginate_attrs(Account, attrs, [:id])

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

      attrs = %{"start_after" => iat, "start_by" => "inserted_at", "per_page" => 5}

      paginator = StartAfterPaginator.paginate_attrs(Account, attrs, @default_allowed_fields)

      assert paginator.pagination.per_page == 5
      assert paginator.pagination.count == 1
    end

    test "returns pagination if given `start_after` exist and `start_by` is :created_at" do
      ensure_num_records(Account, 2)

      iats = from(a in Account, select: a.inserted_at, order_by: a.inserted_at)

      [iat | _] =
        iats
        |> Repo.all()

      attrs = %{"start_after" => iat, "start_by" => "created_at", "per_page" => 5}

      paginator =
        StartAfterPaginator.paginate_attrs(
          Account,
          attrs,
          @default_allowed_fields,
          Repo,
          @default_mapped_fields
        )

      assert paginator.pagination.per_page == 5
    end

    test "returns pagination if given `start_after` exist and `start_by` is :updated_at" do
      ensure_num_records(Account, 2)

      uats = from(a in Account, select: a.updated_at, order_by: a.updated_at)

      [uat | _] =
        uats
        |> Repo.all()

      attrs = %{"start_after" => uat, "start_by" => "updated_at", "per_page" => 5}

      paginator = StartAfterPaginator.paginate_attrs(Account, attrs, @default_allowed_fields)

      assert paginator.pagination.per_page == 5
      assert paginator.pagination.count == 1
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

      attrs = %{
        "start_by" => :id,
        "sort_by" => :id,
        "start_after" => first_id,
        "per_page" => per_page
      }

      paginator = StartAfterPaginator.paginate(Account, attrs)

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

    test "returns pagination data from the beginning if given start_after is nil" do
      per_page = 10

      # Generate 10 accounts
      # Example: [%{id: "acc_1"}, %{id: "acc_2"}, ... , %{id: "acc_10"}]
      ensure_num_records(Account, per_page)

      records_id = from(a in Account, select: a.id, order_by: a.id)

      records_id =
        records_id
        |> Repo.all()

      attrs = %{
        "start_by" => :id,
        "sort_by" => :id,
        "start_after" => {:ok, nil},
        "per_page" => per_page
      }

      paginator = StartAfterPaginator.paginate(Account, attrs)

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

    test "returns :error if the `start_after` cannot be casted to `start_by`" do
      total = 10
      per_page = 10
      ensure_num_records(Account, total)

      attrs = %{
        "start_by" => :inserted_at,
        "start_after" => "acc_1",
        "sort_by" => :id,
        "per_page" => per_page
      }

      paginator = StartAfterPaginator.paginate(Account, attrs)

      msg =
        ""
        |> Kernel.<>("Invalid `start_after` or `start_by` provided. ")
        |> Kernel.<>("Given `acc_1` cannot be casted to given `inserted_at`.")

      assert paginator === {:error, :invalid_parameter, msg}
    end

    test "returns :error if start_after doesn't exist" do
      total = 10
      per_page = 10
      ensure_num_records(Account, total)

      attrs = %{
        "start_by" => :id,
        "start_after" => "1",
        "sort_by" => :id,
        "per_page" => per_page
      }

      paginator = StartAfterPaginator.paginate(Account, attrs)

      assert paginator === {:error, :unauthorized}
    end

    test "returns pagination data beginning with the 4th record when given `start_after` to 3th record's id" do
      ensure_num_records(Account, 10)

      records = from(a in Account, select: a, order_by: a.id)

      [_, _, start_after_record, expected_head_record | _] = Repo.all(records)

      attrs = %{
        "start_by" => :id,
        "start_after" => start_after_record.id,
        "per_page" => 5,
        "sort_by" => :id,
        "sort_dir" => "asc"
      }

      %{data: data} = StartAfterPaginator.paginate(Account, attrs)

      [head_record | _] = data

      assert head_record.id == expected_head_record.id
    end
  end

  describe "EWallet.Web.StartAfterPaginator.map_fields/2" do
    test "returns default field when the value is nil" do
      attrs = %{"sort_by" => nil}

      # Assert nil value
      sort_by = StartAfterPaginator.map_atom_attr(attrs, "sort_by", "id", @default_mapped_fields)
      assert sort_by == :id

      # Assert non-existing value
      start_by =
        StartAfterPaginator.map_atom_attr(attrs, "start_by", "id", @default_mapped_fields)

      assert start_by == :id
    end

    test "returns mapped field when the value exists the mapping" do
      attrs = %{"sort_by" => "created_at", "start_by" => nil}

      # Assert original value exists in the `@default_mapped_fields`
      sort_by = StartAfterPaginator.map_atom_attr(attrs, "sort_by", "id", @default_mapped_fields)
      assert sort_by == :inserted_at

      # Assert default value exists in the `@default_mapped_fields`
      start_by =
        StartAfterPaginator.map_atom_attr(attrs, "start_by", "created_at", @default_mapped_fields)

      assert start_by == :inserted_at
    end

    test "returns original value when the value is non-nil and non-exist in the mapping" do
      attrs = %{"sort_by" => "id"}

      sort_by =
        StartAfterPaginator.map_atom_attr(attrs, "sort_by", "name", @default_mapped_fields)

      assert sort_by == :id
    end
  end
end
