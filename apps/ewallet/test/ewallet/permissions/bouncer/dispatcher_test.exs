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

defmodule EWallet.DispatcherTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Bouncer.{Permission, Dispatcher, DispatchConfig}
  alias EWalletDB.{Account, Wallet}

  describe "scoped_query/2" do
    test "calls the appropriate scope module" do
      permission = %Permission{
        global_abilities: %{account_wallets: :global, end_user_wallets: :global},
        schema: Wallet
      }

      res = Dispatcher.scoped_query(permission, DispatchConfig)
      assert res == Wallet
    end
  end

  describe "get_owner_uuids/2" do
    test "calls the appropriate target module" do
      wallet = insert(:wallet)
      res = Dispatcher.get_owner_uuids(wallet, DispatchConfig)
      assert res == [wallet.user_uuid]
    end
  end

  describe "get_target_types/2" do
    test "calls the appropriate target module" do
      res = Dispatcher.get_target_types(Wallet, DispatchConfig)
      assert res == [:account_wallets, :end_user_wallets]
    end
  end

  describe "get_target_type/2" do
    test "calls the appropriate target modulee" do
      wallet = insert(:wallet)
      res = Dispatcher.get_target_type(wallet, DispatchConfig)
      assert res == :end_user_wallets
    end
  end

  describe "get_query_actor_records/2" do
    test "calls the appropriate actor module" do
      permission = %Permission{type: :accounts, actor: insert(:admin)}
      res = Dispatcher.get_query_actor_records(permission, DispatchConfig)
      assert res != nil
    end
  end

  describe "get_actor_accounts/2" do
    test "calls the appropriate actor module" do
      user = insert(:admin)
      res = Dispatcher.get_actor_accounts(user, DispatchConfig)
      assert res != nil
    end
  end

  describe "get_target_accounts/2" do
    test "calls the appropriate actor module" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)

      accounts = Dispatcher.get_target_accounts(wallet, DispatchConfig)
      assert Enum.map(accounts, fn a -> a.uuid end) == [account.uuid]
    end
  end
end
