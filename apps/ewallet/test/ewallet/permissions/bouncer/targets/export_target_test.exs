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

defmodule EWallet.Bouncer.ExportTargetTest do
  use EWallet.DBCase, async: true
  import EWalletDB.{Factory}
  alias EWalletDB.Membership
  alias EWallet.Bouncer.{ExportTarget, DispatchConfig}
  alias ActivityLogger.System

  describe "get_owner_uuids/1" do
    test "returns the list of UUIDs owning the admin created export" do
      admin = insert(:admin)
      export = insert(:export, user: admin)
      res = ExportTarget.get_owner_uuids(export)
      assert res == [admin.uuid]
    end

    test "returns the list of UUIDs owning the key created export" do
      key = insert(:key)
      export = insert(:export, key: key)
      res = ExportTarget.get_owner_uuids(export)
      assert res == [key.uuid]
    end
  end

  describe "get_target_types/0" do
    test "returns a list of types" do
      assert ExportTarget.get_target_types() == [:exports]
    end
  end

  describe "get_target_type/1" do
    test "returns the type of the given export" do
      assert ExportTarget.get_target_type(ExchangePair) == :exports
    end
  end

  describe "get_target_accounts/2" do
    test "returns the list of accounts having rights on the admin created export" do
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      admin_1 = insert(:admin)
      admin_2 = insert(:admin)

      {:ok, _} = Membership.assign(admin_1, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(admin_1, account_2, "admin", %System{})
      {:ok, _} = Membership.assign(admin_2, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(admin_2, account_3, "admin", %System{})

      export = insert(:export, user: admin_1)

      target_accounts_uuids =
        export |> ExportTarget.get_target_accounts(DispatchConfig) |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(target_accounts_uuids, account_1.uuid)
      assert Enum.member?(target_accounts_uuids, account_2.uuid)
    end

    test "returns the list of accounts having rights on the key created export" do
      key = insert(:key)
      export = insert(:export, key: key)
      assert ExportTarget.get_target_accounts(export, DispatchConfig) == []
    end
  end
end
