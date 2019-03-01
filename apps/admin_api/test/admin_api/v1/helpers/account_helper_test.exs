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

defmodule AdminAPI.V1.AccountHelperTest do
  use AdminAPI.ConnCase, async: true
  import EWalletDB.Factory
  alias AdminAPI.V1.AccountHelper
  alias Plug.Conn

  describe "get_accessible_account_uuids/1" do
    setup do
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      %{
        account_1: account_1,
        account_2: account_2,
        account_3: account_3
      }
    end

    test "returns all accessible account uuids when given an admin user", context do
      admin = insert(:admin)
      _ = insert(:membership, user: admin, account: context.account_2)
      _ = insert(:membership, user: admin, account: context.account_3)

      conn = %Conn{
        assigns: %{admin_user: admin}
      }

      uuids = AccountHelper.get_accessible_account_uuids(conn.assigns)

      assert Enum.count(uuids) == 2
      refute Enum.member?(uuids, context.account_1.uuid)
      assert Enum.member?(uuids, context.account_2.uuid)
      assert Enum.member?(uuids, context.account_3.uuid)
    end
  end
end
