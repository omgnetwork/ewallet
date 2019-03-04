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

defmodule EWallet.Bouncer.UserScopeTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{Permission, UserScope}
  alias EWalletDB.{AccountUser, Membership, Repo}
  alias ActivityLogger.System

  describe "scope_query/1 with global abilities (account: global / end_user:*)" do
    test "returns User as queryable when 'global / global' ability" do
      actor = insert(:admin)

      admin_1 = insert(:admin)
      admin_2 = insert(:admin)
      admin_3 = insert(:admin)

      user_1 = insert(:user)
      user_2 = insert(:user)
      user_3 = insert(:user)

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          admin_users: :global,
          end_users: :global
        },
        account_abilities: %{}
      }

      query = UserScope.scoped_query(permission)
      user_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(user_uuids, admin_1.uuid)
      assert Enum.member?(user_uuids, admin_2.uuid)
      assert Enum.member?(user_uuids, admin_3.uuid)
      assert Enum.member?(user_uuids, user_1.uuid)
      assert Enum.member?(user_uuids, user_2.uuid)
      assert Enum.member?(user_uuids, user_3.uuid)
    end

    test "returns all users the actor (user) has access to when 'global / accounts' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      admin_1 = insert(:admin)
      admin_2 = insert(:admin)
      admin_3 = insert(:admin)

      user_1 = insert(:user)
      user_2 = insert(:user)
      user_3 = insert(:user)

      # users for accounts with memberships
      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      user_1 = insert(:user, user_uuid: nil, account_uuid: account_1.uuid)

      user_2 = insert(:user, user_uuid: nil, account_uuid: account_1.uuid)

      user_3 = insert(:user, user_uuid: nil, account_uuid: account_2.uuid)

      user_4 = insert(:user, user_uuid: nil, account_uuid: account_3.uuid)

      user_5 = insert(:user, user_uuid: nil, account_uuid: account_4.uuid)

      # users for users linked with accounts with memberships
      {:ok, _} = AccountUser.link(account_1.uuid, end_user_1.uuid, %System{})

      user_6 = insert(:user, user_uuid: end_user_1.uuid, account_uuid: nil)

      user_7 = insert(:user, user_uuid: end_user_1.uuid, account_uuid: nil)

      user_8 = insert(:user, user_uuid: end_user_2.uuid, account_uuid: nil)

      permission = %Permission{
        actor: actor,
        global_abilities: %{
          admin_users: :global,
          end_users: :accounts
        },
        account_abilities: %{}
      }

      query = UserScope.scoped_query(permission)
      user_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(user_uuids, user_1.uuid)
      assert Enum.member?(user_uuids, user_2.uuid)
      assert Enum.member?(user_uuids, user_3.uuid)
      assert Enum.member?(user_uuids, user_4.uuid)
      assert Enum.member?(user_uuids, user_5.uuid)
      assert Enum.member?(user_uuids, user_6.uuid)
      assert Enum.member?(user_uuids, user_7.uuid)
      refute Enum.member?(user_uuids, user_8.uuid)
      assert length(user_uuids) == 7
    end
  end
end
