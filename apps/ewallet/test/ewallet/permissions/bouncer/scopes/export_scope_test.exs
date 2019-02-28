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

defmodule EWallet.Bouncer.ExportScopeTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{Permission, ExportScope}
  alias EWalletDB.{Export, Repo}

  describe "scope_query/1 with global abilities" do
    test "returns Export as queryable when 'global' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{exports: :global},
        account_abilities: %{}
      }

      assert ExportScope.scoped_query(permission) == Export
    end

    test "returns no exports when 'accounts' ability" do
      actor = insert(:admin)

      _export_1 = insert(:export, user: actor)
      _export_2 = insert(:export, user: actor)

      permission = %Permission{
        actor: actor,
        global_abilities: %{exports: :accounts},
        account_abilities: %{}
      }

      assert ExportScope.scoped_query(permission) == nil
    end

    test "returns all exports the actor (admin user) has access to when 'self' ability" do
      actor = insert(:admin)

      export_1 = insert(:export, user: actor)
      export_2 = insert(:export, user: actor)
      export_3 = insert(:export)
      export_4 = insert(:export)

      permission = %Permission{
        actor: actor,
        global_abilities: %{exports: :self},
        account_abilities: %{}
      }

      query = ExportScope.scoped_query(permission)
      export_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert length(export_uuids) == 2
      assert Enum.member?(export_uuids, export_1.uuid)
      assert Enum.member?(export_uuids, export_2.uuid)
      refute Enum.member?(export_uuids, export_3.uuid)
      refute Enum.member?(export_uuids, export_4.uuid)
    end

    test "returns all exports the actor (end user) has access to when 'self' ability" do
      actor = insert(:user)

      _export_1 = insert(:export, user: actor)
      _export_2 = insert(:export, user: actor)
      _export_3 = insert(:export)
      _export_4 = insert(:export)

      permission = %Permission{
        actor: actor,
        global_abilities: %{exports: :self},
        account_abilities: %{}
      }

      assert ExportScope.scoped_query(permission) == nil
    end

    test "returns all exports the actor (key) has access to when 'self' ability" do
      actor = insert(:key)

      export_1 = insert(:export, key: actor)
      export_2 = insert(:export, key: actor)
      export_3 = insert(:export)
      export_4 = insert(:export)

      permission = %Permission{
        actor: actor,
        global_abilities: %{exports: :self},
        account_abilities: %{}
      }

      query = ExportScope.scoped_query(permission)
      export_uuids = query |> Repo.all() |> Enum.map(fn a -> a.uuid end)

      assert length(export_uuids) == 2
      assert Enum.member?(export_uuids, export_1.uuid)
      assert Enum.member?(export_uuids, export_2.uuid)
      refute Enum.member?(export_uuids, export_3.uuid)
      refute Enum.member?(export_uuids, export_4.uuid)
    end

    test "returns nil when 'none' ability" do
      actor = insert(:admin)

      _export_1 = insert(:export, user: actor)
      _export_2 = insert(:export, user: actor)

      permission = %Permission{
        actor: actor,
        global_abilities: %{exports: :none},
        account_abilities: %{}
      }

      assert ExportScope.scoped_query(permission) == nil
    end
  end
end
