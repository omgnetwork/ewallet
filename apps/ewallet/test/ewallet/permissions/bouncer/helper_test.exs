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

defmodule EWallet.Bouncer.HelperTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.Helper
  alias EWalletDB.Account

  describe "get_actor/1" do
    test "returns the admin user when admin user" do
      res = Helper.get_actor(%{admin_user: "admin_user"})
      assert res == "admin_user"
    end

    test "returns the end user when end user" do
      res = Helper.get_actor(%{end_user: "end_user"})
      assert res == "end_user"
    end

    test "returns the key when key" do
      res = Helper.get_actor(%{key: "key"})
      assert res == "key"
    end

    test "returns the end user when originator" do
      res = Helper.get_actor(%{originator: %{end_user: "admin_user"}})
      assert res == "admin_user"
    end

    test "returns the nil if not handled" do
      res = Helper.get_actor(%{something_else: "something_else"})
      assert res == nil
    end
  end

  describe "extract_permission/2" do
    test "returns the appropriate permission when 3 levels" do
      permissions = %{"super_admin" => %{accounts: %{read: :global}}}
      res = Helper.extract_permission(permissions, ["super_admin", :accounts, :read])
      assert res == :global
    end

    test "returns the appropriate permission when 1 level deep" do
      permissions = %{"super_admin" => :global}
      res = Helper.extract_permission(permissions, ["super_admin", :accounts, :read])
      assert res == :global
    end
  end

  describe "query_with_membership_for/2" do
    test "builds a join query when admin user" do
      admin = insert(:admin)
      res = Helper.query_with_membership_for(admin, Account)
      assert %Ecto.Query{} = res
    end

    test "builds a join query when end user" do
      user = insert(:user)
      res = Helper.query_with_membership_for(user, Account)
      assert %Ecto.Query{} = res
    end

    test "builds a join query when key" do
      key = insert(:key)
      res = Helper.query_with_membership_for(key, Account)
      assert %Ecto.Query{} = res
    end
  end
end
