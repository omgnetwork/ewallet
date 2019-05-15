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

defmodule EWallet.Bouncer.BlockchainWalletScopeTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{Permission, BlockchainWalletScope}
  alias EWalletDB.Repo
  alias Utils.Helpers.UUID

  describe "scope_query/1 with global abilities" do
    test "returns BlockchainWallet as queryable when 'global' ability" do
      actor = insert(:admin)

      blockchain_wallet_1 = insert(:blockchain_wallet)
      blockchain_wallet_2 = insert(:blockchain_wallet)

      permission = %Permission{
        actor: actor,
        global_abilities: %{blockchain_wallets: :global},
        account_abilities: %{}
      }

      query = BlockchainWalletScope.scoped_query(permission)
      blockchain_wallet_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert length(blockchain_wallet_uuids) == 2
      assert Enum.member?(blockchain_wallet_uuids, blockchain_wallet_1.uuid)
      assert Enum.member?(blockchain_wallet_uuids, blockchain_wallet_2.uuid)
    end

    test "returns all blockchain wallets the actor has access to when 'accounts' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{blockchain_wallets: :accounts},
        account_abilities: %{}
      }

      assert BlockchainWalletScope.scoped_query(permission) == nil
    end

    test "returns BlockchainWallet as queryable when 'self' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{blockchain_wallets: :self},
        account_abilities: %{}
      }

      assert BlockchainWalletScope.scoped_query(permission) == nil
    end

    test "returns nil as queryable when 'none' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{blockchain_wallets: :none},
        account_abilities: %{}
      }

      assert BlockchainWalletScope.scoped_query(permission) == nil
    end
  end

  describe "scope_query/1 with account abilities" do
    test "returns BlockchainWallet as queryable when 'global' ability" do
      actor = insert(:admin)

      blockchain_wallet_1 = insert(:blockchain_wallet)
      blockchain_wallet_2 = insert(:blockchain_wallet)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{blockchain_wallets: :global}
      }

      query = BlockchainWalletScope.scoped_query(permission)
      blockchain_wallet_uuids = query |> Repo.all() |> UUID.get_uuids()

      assert length(blockchain_wallet_uuids) == 2
      assert Enum.member?(blockchain_wallet_uuids, blockchain_wallet_1.uuid)
      assert Enum.member?(blockchain_wallet_uuids, blockchain_wallet_2.uuid)
    end

    test "returns all blockchain wallets the actor has access to when 'accounts' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{blockchain_wallets: :accounts}
      }

      assert BlockchainWalletScope.scoped_query(permission) == nil
    end

    test "returns BlockchainWallet as queryable when 'self' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{blockchain_wallets: :self}
      }

      assert BlockchainWalletScope.scoped_query(permission) == nil
    end

    test "returns nil as queryable when 'none' ability" do
      actor = insert(:admin)

      permission = %Permission{
        actor: actor,
        global_abilities: %{},
        account_abilities: %{blockchain_wallets: :none}
      }

      assert BlockchainWalletScope.scoped_query(permission) == nil
    end
  end
end
