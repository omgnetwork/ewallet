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

defmodule EWallet.Bouncer.MembershipTargetTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{MembershipTarget, DispatchConfig}
  alias Utils.Helpers.UUID

  describe "get_owner_uuids/1" do
    test "returns the list of UUIDs owning the user's membership" do
      user = insert(:user)
      account = insert(:account)
      membership = insert(:membership, account: account, user: user, key: nil)
      res = MembershipTarget.get_owner_uuids(membership)
      assert res == [account.uuid, user.uuid]
    end

    test "returns the list of UUIDs owning the key's membership" do
      key = insert(:key)
      account = insert(:account)
      membership = insert(:membership, account: account, key: key, user: nil)
      res = MembershipTarget.get_owner_uuids(membership)
      assert res == [account.uuid, key.uuid]
    end
  end

  describe "get_target_types/0" do
    test "returns a list of types" do
      assert MembershipTarget.get_target_types() == [:memberships]
    end
  end

  describe "get_target_type/1" do
    test "returns the type of the given membership" do
      assert MembershipTarget.get_target_type(Key) == :memberships
    end
  end

  describe "get_target_accounts/2" do
    test "returns the list of accounts having rights on the membership" do
      account = insert(:account)
      _ = insert(:account)
      membership = insert(:membership, account: account)

      target_accounts_uuids =
        membership
        |> MembershipTarget.get_target_accounts(DispatchConfig)
        |> UUID.get_uuids()

      assert Enum.member?(target_accounts_uuids, account.uuid)
    end
  end
end
