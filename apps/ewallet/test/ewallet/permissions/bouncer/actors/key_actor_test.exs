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

defmodule EWallet.Bouncer.KeyActorTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.KeyActor
  alias EWalletDB.Membership
  alias ActivityLogger.System

  describe "get_actor_accounts/1" do
    test "gets all the accounts in which the key has memberships" do
      key = insert(:key)
      account_1 = insert(:account)
      account_2 = insert(:account)

      {:ok, _} = Membership.assign(key, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(key, account_2, "viewer", %System{})

      account_uuids =
        key
        |> KeyActor.get_actor_accounts()
        |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(account_uuids, account_1.uuid)
      assert Enum.member?(account_uuids, account_2.uuid)
    end
  end
end
