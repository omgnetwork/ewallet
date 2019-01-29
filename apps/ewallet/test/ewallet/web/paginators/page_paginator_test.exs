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

defmodule EWallet.Web.PagePaginatorTest do
  use EWallet.DBCase, async: true
  alias EWallet.Web.Paginator
  alias EWallet.Web.PagePaginator
  alias EWalletDB.Account

  describe "EWallet.Web.PagePaginator.paginate/3" do
    test "returns a EWallet.Web.Paginator with data and pagination attributes when query with page" do
      paginator = PagePaginator.paginate(Account, %{"page" => 1, "per_page" => 10})

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
      paginator = PagePaginator.paginate(Account, %{"page" => page, "per_page" => per_page})

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
  end
end
