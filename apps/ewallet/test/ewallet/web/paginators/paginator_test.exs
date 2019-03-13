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

    test "returns :error if given attrs.page is a negative integer" do
      result = Paginator.paginate_attrs(Account, %{"page" => -1})
      assert {:error, :invalid_parameter, "`page` must be non-negative integer"} = result
    end

    test "returns :error if given attrs.page is an invalid integer string" do
      result = Paginator.paginate_attrs(Account, %{"page" => "page what?"})
      assert {:error, :invalid_parameter, "`page` must be non-negative integer"} = result
    end

    test "returns :error if given attrs.per_page is a negative integer" do
      result = Paginator.paginate_attrs(Account, %{"per_page" => -1})

      assert {:error, :invalid_parameter, "`per_page` must be non-negative, non-zero integer"} =
               result
    end

    test "returns :error if given attrs.per_page is zero" do
      result = Paginator.paginate_attrs(Account, %{"per_page" => 0})

      assert {:error, :invalid_parameter, "`per_page` must be non-negative, non-zero integer"} =
               result
    end

    test "returns :error if given attrs.per_page is a string" do
      result = Paginator.paginate_attrs(Account, %{"per_page" => "per page what?"})
      assert {:error, :invalid_parameter, "`per_page` must be non-negative integer"} = result
    end

    test "returns :error if given both attrs.start_after and attrs.page" do
      result =
        Paginator.paginate_attrs(Account, %{
          "page" => 1,
          "per_page" => 10,
          "start_after" => "acc_1234"
        })

      assert {:error, :invalid_parameter, "`page` cannot be used with `start_after`"} = result
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
