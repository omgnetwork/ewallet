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

defmodule EWallet.Bouncer.AccountScopeTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{Permission, AccountScope}
  alias EWalletDB.{Account, Membership, Repo}
  alias ActivityLogger.System
  alias Utils.Helpers.UUID

  describe "scope_query/1 with global abilities" do
    test "returns Account as queryable when 'global' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{accounts: :global},
        account_abilities: %{}
      }

      assert AccountScope.scoped_query(permission) == Account
    end

    test "returns all accounts the actor (user) has access to when 'accounts' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{accounts: :accounts},
        account_abilities: %{}
      }

      query = AccountScope.scoped_query(permission)
      account_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert Enum.member?(account_uuids, account_1.uuid)
      assert Enum.member?(account_uuids, account_2.uuid)
      refute Enum.member?(account_uuids, account_3.uuid)
    end

    test "returns all accounts the actor (key) has access to when 'accounts' ability" do
      actor = insert(:key)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{accounts: :accounts},
        account_abilities: %{}
      }

      query = AccountScope.scoped_query(permission)
      account_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert Enum.member?(account_uuids, account_1.uuid)
      assert Enum.member?(account_uuids, account_2.uuid)
      refute Enum.member?(account_uuids, account_3.uuid)
    end

    test "returns nil when 'self' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      _account_3 = insert(:account)

      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{accounts: :self},
        account_abilities: %{}
      }

      assert AccountScope.scoped_query(permission) == nil
    end

    test "returns nil when 'none' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      _account_3 = insert(:account)

      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{accounts: :none},
        account_abilities: %{}
      }

      assert AccountScope.scoped_query(permission) == nil
    end
  end

  describe "scope_query/1 with account abilities" do
    test "returns Account as queryable when 'global' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{accounts: :global}
      }

      assert AccountScope.scoped_query(permission) == Account
    end

    test "returns all accounts the actor (user) has access to when 'accounts' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{accounts: :accounts}
      }

      query = AccountScope.scoped_query(permission)
      account_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert Enum.member?(account_uuids, account_1.uuid)
      assert Enum.member?(account_uuids, account_2.uuid)
      refute Enum.member?(account_uuids, account_3.uuid)
    end

    test "returns all accounts the actor (key) has access to when 'accounts' ability" do
      actor = insert(:key)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)

      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{accounts: :accounts}
      }

      query = AccountScope.scoped_query(permission)
      account_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert Enum.member?(account_uuids, account_1.uuid)
      assert Enum.member?(account_uuids, account_2.uuid)
      refute Enum.member?(account_uuids, account_3.uuid)
    end

    test "returns nil when 'self' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      _account_3 = insert(:account)

      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{accounts: :self}
      }

      assert AccountScope.scoped_query(permission) == nil
    end

    test "returns nil when 'none' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      _account_3 = insert(:account)

      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{accounts: :none}
      }

      assert AccountScope.scoped_query(permission) == nil
    end
  end
end
