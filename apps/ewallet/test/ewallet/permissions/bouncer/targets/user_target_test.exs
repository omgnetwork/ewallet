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

defmodule EWallet.Bouncer.UserTargetTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWalletDB.{Membership, AccountUser}
  alias EWallet.Bouncer.{UserTarget, DispatchConfig}
  alias ActivityLogger.System
  alias Utils.Helpers.UUID

  describe "get_owner_uuids/1" do
    test "returns the list of UUIDs owning the user" do
      user = insert(:user)
      res = UserTarget.get_owner_uuids(user)
      assert res == [user.uuid]
    end
  end

  describe "get_target_types/0" do
    test "returns a list of types" do
      assert UserTarget.get_target_types() == [:admin_users, :end_users]
    end
  end

  describe "get_target_type/1" do
    test "returns the type of the given user when it's an admin user" do
      admin = insert(:admin)
      assert UserTarget.get_target_type(admin) == :admin_users
    end

    test "returns the type of the given user when it's an end user" do
      user = insert(:user)
      assert UserTarget.get_target_type(user) == :end_users
    end
  end

  describe "get_target_accounts/2" do
    test "returns the list of accounts having rights on the admin user" do
      user = insert(:admin)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_unlinked = insert(:account)
      Membership.assign(user, account_1, "admin", %System{})
      Membership.assign(user, account_2, "viewer", %System{})

      target_accounts_uuids =
        user |> UserTarget.get_target_accounts(DispatchConfig) |> UUID.get_uuids()

      assert length(target_accounts_uuids) == 2
      assert Enum.member?(target_accounts_uuids, account_1.uuid)
      assert Enum.member?(target_accounts_uuids, account_2.uuid)
      refute Enum.member?(target_accounts_uuids, account_unlinked.uuid)
    end

    test "returns the list of accounts having rights on the end user" do
      user = insert(:user)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_unlinked = insert(:account)
      {:ok, _} = AccountUser.link(account_1.uuid, user.uuid, %System{})
      {:ok, _} = AccountUser.link(account_2.uuid, user.uuid, %System{})

      target_accounts_uuids =
        user |> UserTarget.get_target_accounts(DispatchConfig) |> UUID.get_uuids()

      assert length(target_accounts_uuids) == 2
      assert Enum.member?(target_accounts_uuids, account_1.uuid)
      assert Enum.member?(target_accounts_uuids, account_2.uuid)
      refute Enum.member?(target_accounts_uuids, account_unlinked.uuid)
    end
  end
end
