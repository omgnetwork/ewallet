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

defmodule EWallet.Bouncer.UserActorTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.UserActor
  alias EWalletDB.{Membership, AccountUser}
  alias ActivityLogger.System

  describe "get_actor_accounts/1 with admin user as actor" do
    test "gets all the accounts in which the user has memberships" do
      admin = insert(:admin)
      account_1 = insert(:account)
      account_2 = insert(:account)

      {:ok, _} = Membership.assign(admin, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(admin, account_2, "viewer", %System{})

      account_uuids =
        admin
        |> UserActor.get_actor_accounts()
        |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(account_uuids, account_1.uuid)
      assert Enum.member?(account_uuids, account_2.uuid)
    end
  end

  describe "get_actor_accounts/2 with end user as actor" do
    test "gets all the accounts linked with the user" do
      user = insert(:user)
      account_1 = insert(:account)
      account_2 = insert(:account)

      {:ok, _} = AccountUser.link(account_1.uuid, user.uuid, %System{})
      {:ok, _} = AccountUser.link(account_2.uuid, user.uuid, %System{})

      account_uuids =
        user
        |> UserActor.get_actor_accounts()
        |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(account_uuids, account_1.uuid)
      assert Enum.member?(account_uuids, account_2.uuid)
    end
  end
end
