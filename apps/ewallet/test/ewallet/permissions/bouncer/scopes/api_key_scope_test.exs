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

defmodule EWallet.Bouncer.APIKeyScopeTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{Permission, APIKeyScope}
  alias EWalletDB.{APIKey, Membership, Repo}
  alias ActivityLogger.System
  alias Utils.Helpers.UUID

  describe "scope_query/1 with global abilities" do
    test "returns APIKey as queryable when 'global' ability" do
      actor = insert(:admin)

      api_key_1 = insert(:api_key)
      api_key_2 = insert(:api_key)
      api_key_3 = insert(:api_key)

      {:ok, _} = APIKey.delete(api_key_3, %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{api_keys: :global},
        account_abilities: %{}
      }

      query = APIKeyScope.scoped_query(permission)
      api_key_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert length(api_key_uuids) == 2
      assert Enum.member?(api_key_uuids, api_key_1.uuid)
      assert Enum.member?(api_key_uuids, api_key_2.uuid)
      refute Enum.member?(api_key_uuids, api_key_3.uuid)
    end

    test "returns all API keys the actor (user) has access to when 'self' ability" do
      user_1 = insert(:admin)
      user_2 = insert(:admin)

      api_key_1 = insert(:api_key, creator_user: user_1)
      api_key_2 = insert(:api_key, creator_user: user_2)
      api_key_3 = insert(:api_key, creator_user: user_1)
      api_key_4 = insert(:api_key, creator_user: user_2)

      permission = %Permission{
        actor: user_2,
        global_abilities: %{api_keys: :self},
        account_abilities: %{}
      }

      query = APIKeyScope.scoped_query(permission)
      api_key_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert length(api_key_uuids) == 2

      refute Enum.member?(api_key_uuids, api_key_1.uuid)
      assert Enum.member?(api_key_uuids, api_key_2.uuid)
      refute Enum.member?(api_key_uuids, api_key_3.uuid)
      assert Enum.member?(api_key_uuids, api_key_4.uuid)
    end

    test "returns all API keys the actor (key) has access to when 'self' ability" do
      key_1 = insert(:key)
      key_2 = insert(:key)

      api_key_1 = insert(:api_key, creator_key: key_1)
      api_key_2 = insert(:api_key, creator_key: key_2)
      api_key_3 = insert(:api_key, creator_key: key_1)
      api_key_4 = insert(:api_key, creator_key: key_2)

      permission = %Permission{
        actor: key_2,
        global_abilities: %{api_keys: :self},
        account_abilities: %{}
      }

      query = APIKeyScope.scoped_query(permission)
      api_key_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert length(api_key_uuids) == 2

      refute Enum.member?(api_key_uuids, api_key_1.uuid)
      assert Enum.member?(api_key_uuids, api_key_2.uuid)
      refute Enum.member?(api_key_uuids, api_key_3.uuid)
      assert Enum.member?(api_key_uuids, api_key_4.uuid)
    end

    test "returns nil when 'none' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)

      _api_key_1 = insert(:api_key)
      _api_key_2 = insert(:api_key)

      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{api_keys: :none},
        account_abilities: %{}
      }

      assert APIKeyScope.scoped_query(permission) == nil
    end
  end

  describe "scope_query/1 with user abilities" do
    test "returns APIKey as queryable when 'global' ability" do
      actor = insert(:admin)

      api_key_1 = insert(:api_key)
      api_key_2 = insert(:api_key)
      api_key_3 = insert(:api_key)

      {:ok, _} = APIKey.delete(api_key_3, %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{api_keys: :global}
      }

      query = APIKeyScope.scoped_query(permission)
      api_key_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert length(api_key_uuids) == 2
      assert Enum.member?(api_key_uuids, api_key_1.uuid)
      assert Enum.member?(api_key_uuids, api_key_2.uuid)
      refute Enum.member?(api_key_uuids, api_key_3.uuid)
    end

    test "returns all API keys the actor (user) has access to when 'self' ability" do
      user_1 = insert(:admin)
      user_2 = insert(:admin)

      api_key_1 = insert(:api_key, creator_user: user_1)
      api_key_2 = insert(:api_key, creator_user: user_2)
      api_key_3 = insert(:api_key, creator_user: user_1)
      api_key_4 = insert(:api_key, creator_user: user_2)

      permission = %Permission{
        actor: user_2,
        global_abilities: %{},
        account_abilities: %{api_keys: :self}
      }

      query = APIKeyScope.scoped_query(permission)
      api_key_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert length(api_key_uuids) == 2

      refute Enum.member?(api_key_uuids, api_key_1.uuid)
      assert Enum.member?(api_key_uuids, api_key_2.uuid)
      refute Enum.member?(api_key_uuids, api_key_3.uuid)
      assert Enum.member?(api_key_uuids, api_key_4.uuid)
    end

    test "returns all API keys the actor (key) has access to when 'self' ability" do
      key_1 = insert(:key)
      key_2 = insert(:key)

      api_key_1 = insert(:api_key, creator_key: key_1)
      api_key_2 = insert(:api_key, creator_key: key_2)
      api_key_3 = insert(:api_key, creator_key: key_1)
      api_key_4 = insert(:api_key, creator_key: key_2)

      permission = %Permission{
        actor: key_2,
        global_abilities: %{},
        account_abilities: %{api_keys: :self}
      }

      query = APIKeyScope.scoped_query(permission)
      api_key_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert length(api_key_uuids) == 2

      refute Enum.member?(api_key_uuids, api_key_1.uuid)
      assert Enum.member?(api_key_uuids, api_key_2.uuid)
      refute Enum.member?(api_key_uuids, api_key_3.uuid)
      assert Enum.member?(api_key_uuids, api_key_4.uuid)
    end

    test "returns nil when 'none' ability" do
      actor = insert(:admin)

      account_1 = insert(:account)
      account_2 = insert(:account)
      _account_3 = insert(:account)

      _api_key_1 = insert(:api_key)
      _api_key_2 = insert(:api_key)

      {:ok, _} = Membership.assign(actor, account_1, "admin", %System{})
      {:ok, _} = Membership.assign(actor, account_2, "viewer", %System{})

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{api_keys: :none}
      }

      assert APIKeyScope.scoped_query(permission) == nil
    end
  end
end
