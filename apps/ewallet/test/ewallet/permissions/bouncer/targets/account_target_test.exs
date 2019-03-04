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

defmodule EWallet.Bouncer.AccountTargetTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{AccountTarget, DispatchConfig}
  alias EWalletDB.{Account, AccountUser, Membership}
  alias ActivityLogger.System

  describe "get_owner_uuids/1" do
    test "returns the list of UUIDs owning the account" do
      account = insert(:account)
      admin_1 = insert(:admin)
      admin_2 = insert(:admin)
      key_1 = insert(:key)
      key_2 = insert(:key)
      user = insert(:user)

      {:ok, _} = Membership.assign(admin_1, account, "admin", %System{})
      {:ok, _} = Membership.assign(admin_2, account, "viewer", %System{})
      {:ok, _} = Membership.assign(key_1, account, "admin", %System{})
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

      uuids = AccountTarget.get_owner_uuids(account)

      assert Enum.member?(uuids, admin_1.uuid)
      assert Enum.member?(uuids, admin_2.uuid)
      assert Enum.member?(uuids, key_1.uuid)
      refute Enum.member?(uuids, key_2.uuid)
      refute Enum.member?(uuids, user.uuid)
    end
  end

  describe "get_target_types/0" do
    test "returns a list of types" do
      assert AccountTarget.get_target_types() == [:accounts]
    end
  end

  describe "get_target_type/1" do
    test "returns the type of the given account" do
      assert AccountTarget.get_target_type(Account) == :accounts
    end
  end

  describe "get_target_accounts/2" do
    test "returns the list of accounts having rights on the current account" do
      account = insert(:account)
      
      target_accounts_uuids = account |> AccountTarget.get_target_accounts(DispatchConfig) |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(target_accounts_uuids, account.uuid)
    end
  end
end
