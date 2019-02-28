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

defmodule EWallet.Bouncer.KeyScopeTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{Permission, KeyScope}
  alias EWalletDB.{Key, Membership, Repo}
  alias ActivityLogger.System

  describe "scope_query/1 with global abilities" do
    test "returns Key as queryable when 'global' ability" do
      actor = insert(:admin)

      key_1 = insert(:key)
      key_2 = insert(:key)

      permission = %Permission{
        actor: actor,
        global_abilities: %{keys: :global},
        account_abilities: %{}
      }

      query = KeyScope.scoped_query(permission)
      key_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(key_uuids, key_1.uuid)
      assert Enum.member?(key_uuids, key_2.uuid)
      assert length(key_uuids) == 2
    end

    test "returns all keys the actor (user) has access to when 'accounts' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      key_1 = insert(:key)
      key_2 = insert(:key)
      key_3 = insert(:key)
      key_4 = insert(:key)

      {:ok, _} = Key.delete(key_4, %System{})

      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      {:ok, _} = Membership.assign(key_1, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(key_2, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(key_1, account_2, "viewer", %System{})
      {:ok, _} = Membership.assign(key_3, account_3, "viewer", %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{keys: :accounts},
        account_abilities: %{}
      }

      query = KeyScope.scoped_query(permission)
      key_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(key_uuids, key_1.uuid)
      assert Enum.member?(key_uuids, key_2.uuid)
      refute Enum.member?(key_uuids, key_3.uuid)
      refute Enum.member?(key_uuids, key_4.uuid)
      assert length(key_uuids) == 2
    end

    test "returns all keys the actor (key) has access to when 'accounts' ability" do
      actor = insert(:key)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      key_1 = insert(:key)
      key_2 = insert(:key)
      key_3 = insert(:key)
      key_4 = insert(:key)

      {:ok, _} = Key.delete(key_4, %System{})

      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      {:ok, _} = Membership.assign(key_1, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(key_2, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(key_1, account_2, "viewer", %System{})
      {:ok, _} = Membership.assign(key_3, account_3, "viewer", %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{keys: :accounts},
        account_abilities: %{}
      }

      query = KeyScope.scoped_query(permission)
      key_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(key_uuids, actor.uuid)
      assert Enum.member?(key_uuids, key_1.uuid)
      assert Enum.member?(key_uuids, key_2.uuid)
      refute Enum.member?(key_uuids, key_3.uuid)
      refute Enum.member?(key_uuids, key_4.uuid)
      assert length(key_uuids) == 3
    end

    test "returns nil when 'self' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)

      key_1 = insert(:key)
      key_2 = insert(:key)

      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      {:ok, _} = Membership.assign(key_1, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(key_2, account_1, "viewer", %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{keys: :self},
        account_abilities: %{}
      }

      assert KeyScope.scoped_query(permission) == nil
    end

    test "returns nil when 'none' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)

      key_1 = insert(:key)
      key_2 = insert(:key)

      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      {:ok, _} = Membership.assign(key_1, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(key_2, account_1, "viewer", %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{keys: :none},
        account_abilities: %{}
      }

      assert KeyScope.scoped_query(permission) == nil
    end
  end

  describe "scope_query/1 with accounts abilities" do
    test "returns Key as queryable when 'global' ability" do
      actor = insert(:admin)

      key_1 = insert(:key)
      key_2 = insert(:key)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{keys: :global}
      }

      query = KeyScope.scoped_query(permission)
      key_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(key_uuids, key_1.uuid)
      assert Enum.member?(key_uuids, key_2.uuid)
      assert length(key_uuids) == 2
    end

    test "returns all keys the actor (user) has access to when 'accounts' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      key_1 = insert(:key)
      key_2 = insert(:key)
      key_3 = insert(:key)
      key_4 = insert(:key)

      {:ok, _} = Key.delete(key_4, %System{})

      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      {:ok, _} = Membership.assign(key_1, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(key_2, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(key_1, account_2, "viewer", %System{})
      {:ok, _} = Membership.assign(key_3, account_3, "viewer", %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{keys: :accounts}
      }

      query = KeyScope.scoped_query(permission)
      key_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(key_uuids, key_1.uuid)
      assert Enum.member?(key_uuids, key_2.uuid)
      refute Enum.member?(key_uuids, key_3.uuid)
      refute Enum.member?(key_uuids, key_4.uuid)
      assert length(key_uuids) == 2
    end

    test "returns all keys the actor (key) has access to when 'accounts' ability" do
      actor = insert(:key)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      key_1 = insert(:key)
      key_2 = insert(:key)
      key_3 = insert(:key)
      key_4 = insert(:key)

      {:ok, _} = Key.delete(key_4, %System{})

      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      {:ok, _} = Membership.assign(key_1, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(key_2, account_1, "viewer", %System{})
      {:ok, _} = Membership.assign(key_1, account_2, "viewer", %System{})
      {:ok, _} = Membership.assign(key_3, account_3, "viewer", %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{keys: :accounts}
      }

      query = KeyScope.scoped_query(permission)
      key_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(key_uuids, actor.uuid)
      assert Enum.member?(key_uuids, key_1.uuid)
      assert Enum.member?(key_uuids, key_2.uuid)
      refute Enum.member?(key_uuids, key_3.uuid)
      refute Enum.member?(key_uuids, key_4.uuid)
      assert length(key_uuids) == 3
    end

    test "returns nil when 'self' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)

      key_1 = insert(:key)
      key_2 = insert(:key)

      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      {:ok, _} = Membership.assign(key_1, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(key_2, account_1, "viewer", %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{keys: :self}
      }

      assert KeyScope.scoped_query(permission) == nil
    end

    test "returns nil when 'none' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)

      key_1 = insert(:key)
      key_2 = insert(:key)

      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      {:ok, _} = Membership.assign(key_1, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(key_2, account_1, "viewer", %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{keys: :none}
      }

      assert KeyScope.scoped_query(permission) == nil
    end
  end
end
