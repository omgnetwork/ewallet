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

defmodule EWallet.Bouncer.MembershipScopeTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{Permission, MembershipScope}
  alias EWalletDB.{Membership, Membership, Repo}
  alias ActivityLogger.System
  alias Utils.Helpers.UUID

  defp scoped_query(type, %Permission{} = permission) do
    actor = insert(type)
    target = insert(type)

    account_1 = insert(:account)
    account_2 = insert(:account)
    _account_3 = insert(:account)

    {:ok, m_1} = Membership.assign(actor, account_1, "admin", %System{})
    {:ok, m_2} = Membership.assign(target, account_1, "viewer", %System{})
    {:ok, m_3} = Membership.assign(target, account_2, "viewer", %System{})
    m_4 = insert(:membership)

    query =
      permission
      |> Map.put(:actor, actor)
      |> MembershipScope.scoped_query()

    membership_uuids = query |> Repo.all() |> UUID.get_uuids()

    {membership_uuids, m_1, m_2, m_3, m_4}
  end

  describe "scope_query/1 with global abilities" do
    test "returns Membership as queryable when 'global' ability" do
      permission = %Permission{
        global_abilities: %{memberships: :global},
        account_abilities: %{}
      }

      {membership_uuids, m_1, m_2, m_3, m_4} = scoped_query(:admin, permission)

      assert length(membership_uuids) == 4

      assert Enum.member?(membership_uuids, m_1.uuid)
      assert Enum.member?(membership_uuids, m_2.uuid)
      assert Enum.member?(membership_uuids, m_3.uuid)
      assert Enum.member?(membership_uuids, m_4.uuid)
    end

    test "returns all memberships the actor (user) has access to when 'accounts' ability" do
      permission = %Permission{
        global_abilities: %{memberships: :accounts},
        account_abilities: %{}
      }

      {membership_uuids, m_1, m_2, m_3, m_4} = scoped_query(:admin, permission)

      assert length(membership_uuids) == 2

      assert Enum.member?(membership_uuids, m_1.uuid)
      assert Enum.member?(membership_uuids, m_2.uuid)
      refute Enum.member?(membership_uuids, m_3.uuid)
      refute Enum.member?(membership_uuids, m_4.uuid)
    end

    test "returns all memberships the actor (key) has access to when 'accounts' ability" do
      permission = %Permission{
        global_abilities: %{memberships: :accounts},
        account_abilities: %{}
      }

      {membership_uuids, m_1, m_2, m_3, m_4} = scoped_query(:key, permission)

      assert length(membership_uuids) == 2

      assert Enum.member?(membership_uuids, m_1.uuid)
      assert Enum.member?(membership_uuids, m_2.uuid)
      refute Enum.member?(membership_uuids, m_3.uuid)
      refute Enum.member?(membership_uuids, m_4.uuid)
    end

    test "returns all memberships the actor (user) has access to when 'self' ability" do
      permission = %Permission{
        global_abilities: %{memberships: :self},
        account_abilities: %{}
      }

      {membership_uuids, m_1, m_2, m_3, m_4} = scoped_query(:admin, permission)

      assert length(membership_uuids) == 1

      assert Enum.member?(membership_uuids, m_1.uuid)
      refute Enum.member?(membership_uuids, m_2.uuid)
      refute Enum.member?(membership_uuids, m_3.uuid)
      refute Enum.member?(membership_uuids, m_4.uuid)
    end

    test "returns all memberships the actor (key) has access to when 'self' ability" do
      permission = %Permission{
        global_abilities: %{memberships: :self},
        account_abilities: %{}
      }

      {membership_uuids, m_1, m_2, m_3, m_4} = scoped_query(:key, permission)

      assert length(membership_uuids) == 1

      assert Enum.member?(membership_uuids, m_1.uuid)
      refute Enum.member?(membership_uuids, m_2.uuid)
      refute Enum.member?(membership_uuids, m_3.uuid)
      refute Enum.member?(membership_uuids, m_4.uuid)
    end

    test "returns nil when 'none' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      _account_3 = insert(:account)

      {:ok, _membership_1} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _membership_2} = Membership.assign(actor, account_2, "viewer", %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{memberships: :none},
        account_abilities: %{}
      }

      assert MembershipScope.scoped_query(permission) == nil
    end
  end

  describe "scope_query/1 with account abilities" do
    test "returns Membership as queryable when 'global' ability" do
      permission = %Permission{
        global_abilities: %{},
        account_abilities: %{memberships: :global}
      }

      {membership_uuids, m_1, m_2, m_3, m_4} = scoped_query(:admin, permission)

      assert length(membership_uuids) == 4

      assert Enum.member?(membership_uuids, m_1.uuid)
      assert Enum.member?(membership_uuids, m_2.uuid)
      assert Enum.member?(membership_uuids, m_3.uuid)
      assert Enum.member?(membership_uuids, m_4.uuid)
    end

    test "returns all memberships the actor (user) has access to when 'accounts' ability" do
      permission = %Permission{
        global_abilities: %{},
        account_abilities: %{memberships: :accounts}
      }

      {membership_uuids, m_1, m_2, m_3, m_4} = scoped_query(:admin, permission)

      assert length(membership_uuids) == 2

      assert Enum.member?(membership_uuids, m_1.uuid)
      assert Enum.member?(membership_uuids, m_2.uuid)
      refute Enum.member?(membership_uuids, m_3.uuid)
      refute Enum.member?(membership_uuids, m_4.uuid)
    end

    test "returns all memberships the actor (key) has access to when 'accounts' ability" do
      permission = %Permission{
        global_abilities: %{},
        account_abilities: %{memberships: :accounts}
      }

      {membership_uuids, m_1, m_2, m_3, m_4} = scoped_query(:key, permission)

      assert length(membership_uuids) == 2

      assert Enum.member?(membership_uuids, m_1.uuid)
      assert Enum.member?(membership_uuids, m_2.uuid)
      refute Enum.member?(membership_uuids, m_3.uuid)
      refute Enum.member?(membership_uuids, m_4.uuid)
    end

    test "returns all memberships the actor (user) has access to when 'self' ability" do
      permission = %Permission{
        global_abilities: %{},
        account_abilities: %{memberships: :self}
      }

      {membership_uuids, m_1, m_2, m_3, m_4} = scoped_query(:admin, permission)

      assert length(membership_uuids) == 1

      assert Enum.member?(membership_uuids, m_1.uuid)
      refute Enum.member?(membership_uuids, m_2.uuid)
      refute Enum.member?(membership_uuids, m_3.uuid)
      refute Enum.member?(membership_uuids, m_4.uuid)
    end

    test "returns all memberships the actor (key) has access to when 'self' ability" do
      permission = %Permission{
        global_abilities: %{},
        account_abilities: %{memberships: :self}
      }

      {membership_uuids, m_1, m_2, m_3, m_4} = scoped_query(:key, permission)

      assert length(membership_uuids) == 1

      assert Enum.member?(membership_uuids, m_1.uuid)
      refute Enum.member?(membership_uuids, m_2.uuid)
      refute Enum.member?(membership_uuids, m_3.uuid)
      refute Enum.member?(membership_uuids, m_4.uuid)
    end

    test "returns nil when 'none' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      _account_3 = insert(:account)

      {:ok, _membership_1} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _membership_2} = Membership.assign(actor, account_2, "viewer", %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{memberships: :none}
      }

      assert MembershipScope.scoped_query(permission) == nil
    end
  end
end
