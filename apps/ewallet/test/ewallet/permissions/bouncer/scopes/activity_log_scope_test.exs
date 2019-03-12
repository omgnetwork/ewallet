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

defmodule EWallet.Bouncer.ActivityLogScopeTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{ActivityLogScope, Permission}
  alias ActivityLogger.ActivityLog

  describe "scope_query/1 with global abilities" do
    test "returns ActivityLog as queryable when 'global' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{activity_logs: :global},
        account_abilities: %{}
      }

      assert ActivityLogScope.scoped_query(permission) == ActivityLog
    end

    test "returns all activity_logs the actor has access to when 'accounts' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{activity_logs: :accounts},
        account_abilities: %{}
      }

      assert ActivityLogScope.scoped_query(permission) == nil
    end

    test "returns ActivityLog as queryable when 'self' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{activity_logs: :self},
        account_abilities: %{}
      }

      assert ActivityLogScope.scoped_query(permission) == nil
    end

    test "returns nil as queryable when 'none' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{activity_logs: :none},
        account_abilities: %{}
      }

      assert ActivityLogScope.scoped_query(permission) == nil
    end
  end

  describe "scope_query/1 with account abilities" do
    test "returns ActivityLog as queryable when 'global' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{activity_logs: :global}
      }

      assert ActivityLogScope.scoped_query(permission) == ActivityLog
    end

    test "returns all activity_logs the actor has access to when 'accounts' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{activity_logs: :accounts}
      }

      assert ActivityLogScope.scoped_query(permission) == nil
    end

    test "returns ActivityLog as queryable when 'self' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{activity_logs: :self}
      }

      assert ActivityLogScope.scoped_query(permission) == nil
    end

    test "returns nil as queryable when 'none' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{activity_logs: :none}
      }

      assert ActivityLogScope.scoped_query(permission) == nil
    end
  end
end
