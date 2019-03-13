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

defmodule EWallet.Bouncer.TokenScopeTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{TokenScope, Permission}
  alias EWalletDB.Repo
  alias Utils.Helpers.UUID

  describe "scope_query/1 with global abilities" do
    test "returns Token as queryable when 'global' ability" do
      actor = insert(:admin)

      token_1 = insert(:token)
      token_2 = insert(:token)
      token_3 = insert(:token)

      permission = %Permission{
        actor: actor,
        global_abilities: %{tokens: :global},
        account_abilities: %{}
      }

      query = TokenScope.scoped_query(permission)
      token_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert length(token_uuids) == 3
      assert Enum.member?(token_uuids, token_1.uuid)
      assert Enum.member?(token_uuids, token_2.uuid)
      assert Enum.member?(token_uuids, token_3.uuid)
    end

    test "returns nil when 'accounts' ability" do
      actor = insert(:admin)
      _token_1 = insert(:token)

      permission = %Permission{
        actor: actor,
        global_abilities: %{tokens: :accounts},
        account_abilities: %{}
      }

      assert TokenScope.scoped_query(permission) == nil
    end

    test "returns nil as queryable when 'self' ability" do
      actor = insert(:admin)
      _token_1 = insert(:token)

      permission = %Permission{
        actor: actor,
        global_abilities: %{tokens: :self},
        account_abilities: %{}
      }

      assert TokenScope.scoped_query(permission) == nil
    end

    test "returns nil as queryable when 'none' ability" do
      actor = insert(:admin)
      _token_1 = insert(:token)

      permission = %Permission{
        actor: actor,
        global_abilities: %{tokens: :none},
        account_abilities: %{}
      }

      assert TokenScope.scoped_query(permission) == nil
    end
  end

  describe "scope_query/1 with account abilities" do
    test "returns Token as queryable when 'global' ability" do
      actor = insert(:admin)

      token_1 = insert(:token)
      token_2 = insert(:token)
      token_3 = insert(:token)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{tokens: :global}
      }

      query = TokenScope.scoped_query(permission)
      token_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert length(token_uuids) == 3
      assert Enum.member?(token_uuids, token_1.uuid)
      assert Enum.member?(token_uuids, token_2.uuid)
      assert Enum.member?(token_uuids, token_3.uuid)
    end

    test "returns nil when 'accounts' ability" do
      actor = insert(:admin)
      _token_1 = insert(:token)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{tokens: :accounts}
      }

      assert TokenScope.scoped_query(permission) == nil
    end

    test "returns nil as queryable when 'self' ability" do
      actor = insert(:admin)
      _token_1 = insert(:token)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{tokens: :self}
      }

      assert TokenScope.scoped_query(permission) == nil
    end

    test "returns nil as queryable when 'none' ability" do
      actor = insert(:admin)
      _token_1 = insert(:token)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{tokens: :none}
      }

      assert TokenScope.scoped_query(permission) == nil
    end
  end
end
