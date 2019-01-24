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

defmodule EWallet.Web.PaginatorTest do
  use EWallet.DBCase, async: true
  import Ecto.Query
  alias EWallet.Web.Paginator
  alias EWalletConfig.Config
  alias EWalletDB.{Account, Repo}
  alias ActivityLogger.System

  describe "EWallet.Web.Paginator.paginate_attrs/2" do
    test "paginates with default values if attrs not given" do
      ensure_num_records(Account, 10)

      paginator = Paginator.paginate_attrs(Account, %{})
      assert Enum.count(paginator.data) == 10
      assert paginator.pagination.per_page == 10
    end

    test "returns a paginator with the given page and per_page" do
      ensure_num_records(Account, 10)

      paginator = Paginator.paginate_attrs(Account, %{"page" => 2, "per_page" => 3})
      assert paginator.pagination.current_page == 2
      assert paginator.pagination.per_page == 3

      # Try with different values to make sure the attributes are respected
      paginator = Paginator.paginate_attrs(Account, %{"page" => 3, "per_page" => 4})
      assert paginator.pagination.current_page == 3
      assert paginator.pagination.per_page == 4
    end

    test "returns a paginator with the given page and per_page as string parameters" do
      ensure_num_records(Account, 10)

      paginator = Paginator.paginate_attrs(Account, %{"page" => "2", "per_page" => "3"})
      assert paginator.pagination.current_page == 2
      assert paginator.pagination.per_page == 3

      # Try with different values to make sure the attributes are respected
      paginator = Paginator.paginate_attrs(Account, %{"page" => "3", "per_page" => "4"})
      assert paginator.pagination.current_page == 3
      assert paginator.pagination.per_page == 4
    end

    test "returns a paginator with the given `start_from` without `start_by`" do
      ensure_num_records(Account, 1)

      id = from(a in Account, select: a.id, order_by: a.id)

      id =
        id
        |> Repo.all()
        |> Enum.at(0)

      paginator =
        Paginator.paginate_attrs(Account, %{"start_from" => id, "per_page" => "5"}, [:id])

      assert paginator.pagination.current_page == 1
      assert paginator.pagination.per_page == 5
      assert paginator.pagination.count == 1
    end

    test "returns a paginator with the given `start_from` and `start_by` equal :inserted_at" do
      ensure_num_records(Account, 1)

      inserted_at = from(a in Account, select: a.inserted_at, order_by: a.inserted_at)

      inserted_at =
        inserted_at
        |> Repo.all()
        |> Enum.at(0)

      paginator =
        Paginator.paginate_attrs(
          Account,
          %{"start_from" => inserted_at, "start_by" => "inserted_at", "per_page" => 5},
          [:id, :inserted_at]
        )

      assert paginator.pagination.current_page == 1
      assert paginator.pagination.per_page == 5
      assert paginator.pagination.count == 1
    end

    test "returns per_page but never greater than the system's _default_ maximum (100)" do
      paginator = Paginator.paginate_attrs(Account, %{"per_page" => 999})
      assert paginator.pagination.per_page == 100
    end

    test "returns per_page but never greater than the system's _defined_ maximum", meta do
      {:ok, [max_per_page: {:ok, _}]} =
        Config.update(
          [
            max_per_page: 20,
            originator: %System{}
          ],
          meta[:config_pid]
        )

      paginator = Paginator.paginate_attrs(Account, %{"per_page" => 100})
      assert paginator.pagination.per_page == 20
    end

    test "returns :error if given attrs.page is a negative integer" do
      result = Paginator.paginate_attrs(Account, %{"page" => -1})
      assert {:error, :invalid_parameter, _} = result
    end

    test "returns :error if given attrs.page is an invalid integer string" do
      result = Paginator.paginate_attrs(Account, %{"page" => "page what?"})
      assert {:error, :invalid_parameter, _} = result
    end

    test "returns :error if given attrs.per_page is a negative integer" do
      result = Paginator.paginate_attrs(Account, %{"per_page" => -1})
      assert {:error, :invalid_parameter, _} = result
    end

    test "returns :error if given attrs.per_page is zero" do
      result = Paginator.paginate_attrs(Account, %{"per_page" => 0})
      assert {:error, :invalid_parameter, _} = result
    end

    test "returns :error if given attrs.per_page is a string" do
      result = Paginator.paginate_attrs(Account, %{"per_page" => "per page what?"})
      assert {:error, :invalid_parameter, _} = result
    end

    test "returrns :error if given both attrs.start_from and attrs.page" do
      result = Paginator.paginate_attrs(Account, %{"page" => 1, "start_from" => "acc_1234"})

      assert {:error, :invalid_parameter, _} = result
    end

    test "returns :error if given attrs.start_by is not a string" do
      result = Paginator.paginate_attrs(Account, %{"start_by" => 1}, [:id])
      assert {:error, :invalid_parameter, _} = result
    end

    test "returns :error if given attrs.start_from doesn't exist" do
      result = Paginator.paginate_attrs(Account, %{"start_from" => "acc_nil"}, [:id])
      assert {:error, :unauthorized} = result
    end

    test "returns :error if given attrs.start_by is not allowed" do
      result =
        Paginator.paginate_attrs(
          Account,
          %{"start_by" => "a", "start_from" => "1"},
          [:id, :create_at]
        )

      assert {:error, :invalid_parameter, _} = result
    end
  end

  describe "EWallet.Web.Paginator.paginate/3" do
    test "returns a EWallet.Web.Paginator with data and pagination attributes when query with page" do
      paginator = Paginator.paginate(Account, %{"page" => 1, "per_page" => 10})

      assert %Paginator{} = paginator
      assert Map.has_key?(paginator, :data)
      assert Map.has_key?(paginator, :pagination)
      assert is_list(paginator.data)
    end

    test "returns correct pagination data when query by given page" do
      total = 10
      page = 2
      per_page = 3

      ensure_num_records(Account, total)
      paginator = Paginator.paginate(Account, %{"page" => page, "per_page" => per_page})

      # Assertions for paginator.pagination
      assert paginator.pagination == %{
               per_page: per_page,
               current_page: page,
               # 2nd page is not the first page
               is_first_page: false,
               # 2nd page is not the last page
               is_last_page: false,
               count: 3
             }
    end

    test "returns correct pagination data when query by given start_by and start_from" do
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

      # Example "acc_6"
      first_record_id = Enum.at(records_id, 0)

      paginator =
        Paginator.paginate(
          Account,
          %{
            "start_by" => :id,
            "start_from" => first_record_id,
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
               current_page: 1,
               is_first_page: true,
               is_last_page: true,
               count: total_records
             }
    end

    test "returns error if start_from doesn't exist" do
      total = 10
      per_page = 10
      ensure_num_records(Account, total)

      paginator =
        Paginator.paginate(
          Account,
          %{"start_by" => :id, "start_from" => "1", "per_page" => per_page}
        )

      assert paginator === {:error, :unauthorized}
    end
  end

  describe "EWallet.Web.Paginator.fetch/3" do
    test "returns a tuple of records and has_more flag" do
      ensure_num_records(Account, 10)

      {records, has_more} = Paginator.fetch(Account, %{"page" => 2, "per_page" => 5})
      assert is_list(records)
      assert is_boolean(has_more)
    end

    # 10 records with 4 per page should yield...
    # Page 1: A0, A1, A2, A3
    # Page 2: A4, A5, A6, A7
    # Page 3: A8, A9
    test "returns correct paged records" do
      ensure_num_records(Account, 10)
      per_page = 4

      query = from(a in Account, select: a.id, order_by: a.id)
      all_ids = Repo.all(query)

      # Page 1
      {records, _} = Paginator.fetch(query, %{"page" => 1, "per_page" => per_page})
      assert records == Enum.slice(all_ids, 0..3)

      # Page 2
      {records, _} = Paginator.fetch(query, %{"page" => 2, "per_page" => per_page})
      assert records == Enum.slice(all_ids, 4..7)

      # Page 3
      {records, _} = Paginator.fetch(query, %{"page" => 3, "per_page" => per_page})
      assert records == Enum.slice(all_ids, 8..9)
    end

    test "returns {_, true} if there are more records to fetch" do
      ensure_num_records(Account, 10)

      # Request page 2 out of div(10, 4) = 3
      result = Paginator.fetch(Account, %{"page" => 2, "per_page" => 4})
      assert {_, true} = result
    end

    test "returns {_, false} if there are no more records to fetch" do
      ensure_num_records(Account, 9)

      # Request page 2 out of div(10, 4) = 3
      result = Paginator.fetch(Account, %{"page" => 3, "per_page" => 3})
      assert {_, false} = result
    end
  end
end
