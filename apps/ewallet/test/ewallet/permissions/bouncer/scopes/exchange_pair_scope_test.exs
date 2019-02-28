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

defmodule EWallet.Bouncer.ExchangePairScopeTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{ExchangePairScope, Permission}
  alias EWalletDB.{Repo, ExchangePair}
  alias ActivityLogger.System

  describe "scope_query/1 with global abilities" do
    test "returns ExchangePair as queryable when 'global' ability" do
      actor = insert(:admin)

      exchange_pair_1 = insert(:exchange_pair)
      exchange_pair_2 = insert(:exchange_pair)
      exchange_pair_3 = insert(:exchange_pair)

      {:ok, _} = ExchangePair.delete(exchange_pair_3, %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{exchange_pairs: :global},
        account_abilities: %{}
      }

      query = ExchangePairScope.scoped_query(permission)
      exchange_pair_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert length(exchange_pair_uuids) == 2
      assert Enum.member?(exchange_pair_uuids, exchange_pair_1.uuid)
      assert Enum.member?(exchange_pair_uuids, exchange_pair_2.uuid)
      refute Enum.member?(exchange_pair_uuids, exchange_pair_3.uuid)
    end

    test "returns all activity_logs the actor has access to when 'accounts' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{exchange_pairs: :accounts},
        account_abilities: %{}
      }

      assert ExchangePairScope.scoped_query(permission) == nil
    end

    test "returns ExchangePair as queryable when 'self' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{exchange_pairs: :self},
        account_abilities: %{}
      }

      assert ExchangePairScope.scoped_query(permission) == nil
    end

    test "returns nil as queryable when 'none' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{exchange_pairs: :none},
        account_abilities: %{}
      }

      assert ExchangePairScope.scoped_query(permission) == nil
    end
  end

  describe "scope_query/1 with account abilities" do
    test "returns ExchangePair as queryable when 'global' ability" do
      actor = insert(:admin)

      exchange_pair_1 = insert(:exchange_pair)
      exchange_pair_2 = insert(:exchange_pair)
      exchange_pair_3 = insert(:exchange_pair)

      {:ok, _} = ExchangePair.delete(exchange_pair_3, %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{exchange_pairs: :global}
      }

      query = ExchangePairScope.scoped_query(permission)
      exchange_pair_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert length(exchange_pair_uuids) == 2
      assert Enum.member?(exchange_pair_uuids, exchange_pair_1.uuid)
      assert Enum.member?(exchange_pair_uuids, exchange_pair_2.uuid)
      refute Enum.member?(exchange_pair_uuids, exchange_pair_3.uuid)
    end

    test "returns all activity_logs the actor has access to when 'accounts' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{exchange_pairs: :accounts}
      }

      assert ExchangePairScope.scoped_query(permission) == nil
    end

    test "returns ExchangePair as queryable when 'self' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{exchange_pairs: :self}
      }

      assert ExchangePairScope.scoped_query(permission) == nil
    end

    test "returns nil as queryable when 'none' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{exchange_pairs: :none}
      }

      assert ExchangePairScope.scoped_query(permission) == nil
    end
  end
end
