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

defmodule AdminAPI.V1.AccountViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.AccountView
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.AccountSerializer

  describe "AdminAPI.V1.AccountView.render/2" do
    test "renders account.json with correct response structure" do
      account = insert(:account)

      expected = %{
        version: @expected_version,
        success: true,
        data: AccountSerializer.serialize(account)
      }

      assert AccountView.render("account.json", %{account: account}) == expected
    end

    test "renders accounts.json with correct response structure" do
      account1 = insert(:account)
      account2 = insert(:account)

      paginator = %Paginator{
        data: [account1, account2],
        pagination: %{
          per_page: 10,
          current_page: 1,
          is_first_page: true,
          is_last_page: false
        }
      }

      expected = %{
        version: @expected_version,
        success: true,
        data: AccountSerializer.serialize(paginator)
      }

      assert AccountView.render("accounts.json", %{accounts: paginator}) == expected
    end
  end
end
