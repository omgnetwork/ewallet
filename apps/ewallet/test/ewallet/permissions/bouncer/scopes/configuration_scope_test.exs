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

defmodule EWallet.Bouncer.ConfigurationScopeTest do
  use EWallet.DBCase, async: true
  alias EWallet.Bouncer.{ConfigurationScope, Permission}
  alias EWalletConfig.{Config, Repo}
  alias EWalletDB.Factory
  alias Utils.Helpers.UUID

  describe "scope_query/1 with global abilities" do
    test "returns Configuration queryable when 'global' ability" do
      actor = Factory.insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{configuration: :global},
        account_abilities: %{}
      }

      query = ConfigurationScope.scoped_query(permission)
      stored_setting_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert length(stored_setting_uuids) == length(Config.settings())
    end

    test "returns all activity_logs the actor has access to when 'accounts' ability" do
      actor = Factory.insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{configuration: :accounts},
        account_abilities: %{}
      }

      assert ConfigurationScope.scoped_query(permission) == nil
    end

    test "returns Configuration as queryable when 'self' ability" do
      actor = Factory.insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{configuration: :self},
        account_abilities: %{}
      }

      assert ConfigurationScope.scoped_query(permission) == nil
    end

    test "returns nil as queryable when 'none' ability" do
      actor = Factory.insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{configuration: :none},
        account_abilities: %{}
      }

      assert ConfigurationScope.scoped_query(permission) == nil
    end
  end

  describe "scope_query/1 with accounts abilities" do
    test "returns Configuration queryable when 'global' ability" do
      actor = Factory.insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{configuration: :global}
      }

      query = ConfigurationScope.scoped_query(permission)
      stored_setting_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert length(stored_setting_uuids) == length(Config.settings())
    end

    test "returns all activity_logs the actor has access to when 'accounts' ability" do
      actor = Factory.insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{configuration: :accounts}
      }

      assert ConfigurationScope.scoped_query(permission) == nil
    end

    test "returns Configuration as queryable when 'self' ability" do
      actor = Factory.insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{configuration: :self}
      }

      assert ConfigurationScope.scoped_query(permission) == nil
    end

    test "returns nil as queryable when 'none' ability" do
      actor = Factory.insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{configuration: :none}
      }

      assert ConfigurationScope.scoped_query(permission) == nil
    end
  end
end
