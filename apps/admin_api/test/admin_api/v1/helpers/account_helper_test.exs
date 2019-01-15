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

  describe "get_current_account/1" do
    test "returns the user's auth_token account when exist" do
      admin = insert(:admin)
      account = insert(:account)
      auth_token = insert(:auth_token, user: admin, account: account, owner_app: "admin_api")

      conn = %Conn{
        assigns: %{admin_user: admin},
        private: %{auth_auth_token: auth_token.token}
      }

      assert AccountHelper.get_current_account(conn).uuid == account.uuid
    end

    test "returns the user's account when the auth_token is not associated with an account" do
      admin = insert(:admin)
      account = insert(:account)
      _ = insert(:membership, user: admin, account: account)
      auth_token = insert(:auth_token, user: admin, account: nil, owner_app: "admin_api")

      conn = %Conn{
        assigns: %{admin_user: admin},
        private: %{auth_auth_token: auth_token.token}
      }

      assert AccountHelper.get_current_account(conn).uuid == account.uuid
    end

    test "returns the key's account when the conn is authenticated using a key" do
      account = insert(:account)
      key = insert(:key, account: account)

      conn = %Conn{
        assigns: %{
          key: key
        }
      }

      assert AccountHelper.get_current_account(conn).uuid == account.uuid
    end
  end

  describe "get_accessible_account_uuids/1" do
    setup do
      account_1 = insert(:account)
      account_2 = insert(:account, parent: account_1)
      account_3 = insert(:account, parent: account_2)

      %{
        account_1: account_1,
        account_2: account_2,
        account_3: account_3
      }
    end

    test "returns all accessible account uuids when given an admin user", context do
      admin = insert(:admin)
      _ = insert(:membership, user: admin, account: context.account_2)

      conn = %Conn{
        assigns: %{admin_user: admin}
      }

      uuids = AccountHelper.get_accessible_account_uuids(conn.assigns)

      assert Enum.count(uuids) == 2
      refute Enum.member?(uuids, context.account_1.uuid)
      assert Enum.member?(uuids, context.account_2.uuid)
      assert Enum.member?(uuids, context.account_3.uuid)
    end

    test "returns all accessible account uuids when given a key", context do
      key = insert(:key, account: context.account_2)

      conn = %Conn{
        assigns: %{
          key: key
        }
      }

      uuids = AccountHelper.get_accessible_account_uuids(conn.assigns)

      assert Enum.count(uuids) == 2
      refute Enum.member?(uuids, context.account_1.uuid)
      assert Enum.member?(uuids, context.account_2.uuid)
      assert Enum.member?(uuids, context.account_3.uuid)
    end
  end
end
