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

defmodule EWallet.Bouncer.MintScopeTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{MintScope, Permission}
  alias EWalletDB.Repo

  describe "scope_query/1 with global abilities" do
    test "returns Mint as queryable when 'global' ability" do
      actor = insert(:admin)

      mint_1 = insert(:mint)
      mint_2 = insert(:mint)
      mint_3 = insert(:mint)

      permission = %Permission{
        actor: actor,
        global_abilities: %{mints: :global},
        account_abilities: %{}
      }

      query = MintScope.scoped_query(permission)
      mint_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert length(mint_uuids) == 3
      assert Enum.member?(mint_uuids, mint_1.uuid)
      assert Enum.member?(mint_uuids, mint_2.uuid)
      assert Enum.member?(mint_uuids, mint_3.uuid)
    end

    test "returns nil when 'accounts' ability" do
      actor = insert(:admin)
      _mint_1 = insert(:mint)

      permission = %Permission{
        actor: actor,
        global_abilities: %{mints: :accounts},
        account_abilities: %{}
      }

      assert MintScope.scoped_query(permission) == nil
    end

    test "returns nil as queryable when 'self' ability" do
      actor = insert(:admin)
      _mint_1 = insert(:mint)

      permission = %Permission{
        actor: actor,
        global_abilities: %{mints: :self},
        account_abilities: %{}
      }

      assert MintScope.scoped_query(permission) == nil
    end

    test "returns nil as queryable when 'none' ability" do
      actor = insert(:admin)
      _mint_1 = insert(:mint)

      permission = %Permission{
        actor: actor,
        global_abilities: %{mints: :none},
        account_abilities: %{}
      }

      assert MintScope.scoped_query(permission) == nil
    end
  end

  describe "scope_query/1 with account abilities" do
    test "returns Mint as queryable when 'global' ability" do
      actor = insert(:admin)

      mint_1 = insert(:mint)
      mint_2 = insert(:mint)
      mint_3 = insert(:mint)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{mints: :global}
      }

      query = MintScope.scoped_query(permission)
      mint_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert length(mint_uuids) == 3
      assert Enum.member?(mint_uuids, mint_1.uuid)
      assert Enum.member?(mint_uuids, mint_2.uuid)
      assert Enum.member?(mint_uuids, mint_3.uuid)
    end

    test "returns nil when 'accounts' ability" do
      actor = insert(:admin)
      _mint_1 = insert(:mint)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{mints: :accounts}
      }

      assert MintScope.scoped_query(permission) == nil
    end

    test "returns nil as queryable when 'self' ability" do
      actor = insert(:admin)
      _mint_1 = insert(:mint)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{mints: :self}
      }

      assert MintScope.scoped_query(permission) == nil
    end

    test "returns nil as queryable when 'none' ability" do
      actor = insert(:admin)
      _mint_1 = insert(:mint)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{mints: :none}
      }

      assert MintScope.scoped_query(permission) == nil
    end
  end
end
