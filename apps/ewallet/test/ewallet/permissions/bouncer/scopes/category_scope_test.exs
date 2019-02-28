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

defmodule EWallet.Bouncer.CategoryScopeTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{CategoryScope, Permission}
  alias EWalletDB.{Repo, Category}
  alias ActivityLogger.System

  describe "scope_query/1 with global abilities" do
    test "returns Category as queryable when 'global' ability" do
      actor = insert(:admin)

      category_1 = insert(:category)
      category_2 = insert(:category)
      category_3 = insert(:category)

      {:ok, _} = Category.delete(category_3, %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{categories: :global},
        account_abilities: %{}
      }

      query = CategoryScope.scoped_query(permission)
      category_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert length(category_uuids) == 2
      assert Enum.member?(category_uuids, category_1.uuid)
      assert Enum.member?(category_uuids, category_2.uuid)
      refute Enum.member?(category_uuids, category_3.uuid)
    end

    test "returns all activity_logs the actor has access to when 'accounts' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{categories: :accounts},
        account_abilities: %{}
      }

      assert CategoryScope.scoped_query(permission) == nil
    end

    test "returns Category as queryable when 'self' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{categories: :self},
        account_abilities: %{}
      }

      assert CategoryScope.scoped_query(permission) == nil
    end

    test "returns nil as queryable when 'none' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{categories: :none},
        account_abilities: %{}
      }

      assert CategoryScope.scoped_query(permission) == nil
    end
  end

  describe "scope_query/1 with account abilities" do
    test "returns Category as queryable when 'global' ability" do
      actor = insert(:admin)

      category_1 = insert(:category)
      category_2 = insert(:category)
      category_3 = insert(:category)

      {:ok, _} = Category.delete(category_3, %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{categories: :global}
      }

      query = CategoryScope.scoped_query(permission)
      category_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert length(category_uuids) == 2
      assert Enum.member?(category_uuids, category_1.uuid)
      assert Enum.member?(category_uuids, category_2.uuid)
      refute Enum.member?(category_uuids, category_3.uuid)
    end

    test "returns all activity_logs the actor has access to when 'accounts' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{categories: :accounts}
      }

      assert CategoryScope.scoped_query(permission) == nil
    end

    test "returns Category as queryable when 'self' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{categories: :self}
      }

      assert CategoryScope.scoped_query(permission) == nil
    end

    test "returns nil as queryable when 'none' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{categories: :none}
      }

      assert CategoryScope.scoped_query(permission) == nil
    end
  end
end
