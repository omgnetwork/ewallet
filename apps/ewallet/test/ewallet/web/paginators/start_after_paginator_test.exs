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
  alias EWallet.Web.Paginator
  alias EWallet.Web.StartAfterPaginator
  alias EWalletConfig.Config
  alias EWalletDB.{Account, Repo}
  alias ActivityLogger.System

  describe "EWallet.Web.StartAfterPaginator.paginate/3" do
    test "returns correct pagination data when query by given start_by and start_after" do
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
      [first_id | ids] = records_id

      paginator =
        StartAfterPaginator.paginate(
          Account,
          %{
            "start_by" => :id,
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
               current_page: 1,
               is_first_page: true,
               is_last_page: true,
               count: total_records - 1,
               start_after: first_id,
               start_by: "id"
             }
    end

    test "returns error if start_after doesn't exist" do
      total = 10
      per_page = 10
      ensure_num_records(Account, total)

      paginator =
        StartAfterPaginator.paginate(
          Account,
          %{"start_by" => :id, "start_after" => "1", "per_page" => per_page}
        )

      assert paginator === {:error, :unauthorized}
    end
  end
end
