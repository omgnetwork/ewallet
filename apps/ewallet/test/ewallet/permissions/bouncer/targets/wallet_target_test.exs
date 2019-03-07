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

defmodule EWallet.Bouncer.WalletTargetTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWalletDB.AccountUser
  alias EWallet.Bouncer.{WalletTarget, DispatchConfig}
  alias ActivityLogger.System

  describe "get_owner_uuids/1" do
    test "returns the list of UUIDs owning the account's wallet" do
      account = insert(:account)
      wallet = insert(:wallet, account: account, user: nil)
      res = WalletTarget.get_owner_uuids(wallet)
      assert res == [account.uuid]
    end

    test "returns the list of UUIDs owning the user's wallet" do
      user = insert(:user)
      wallet = insert(:wallet, user: user, account: nil)
      res = WalletTarget.get_owner_uuids(wallet)
      assert res == [user.uuid]
    end
  end

  describe "get_target_types/0" do
    test "returns a list of types" do
      assert WalletTarget.get_target_types() == [:account_wallets, :end_user_wallets]
    end
  end

  describe "get_target_type/1" do
    test "returns the type of the given wallet when it's an account wallet" do
      account = insert(:account)
      wallet = insert(:wallet, account: account, user: nil)
      assert WalletTarget.get_target_type(wallet) == :account_wallets
    end

    test "returns the type of the given wallet when it's a user wallet" do
      user = insert(:user)
      wallet = insert(:wallet, user: user, account: nil)
      assert WalletTarget.get_target_type(wallet) == :end_user_wallets
    end
  end

  describe "get_target_accounts/2" do
    test "returns the list of accounts having rights on the account wallet" do
      account = insert(:account)
      wallet = insert(:wallet, account: account, user: nil)
      account_unlinked = insert(:account)

      target_accounts_uuids =
        wallet |> WalletTarget.get_target_accounts(DispatchConfig) |> Enum.map(fn a -> a.uuid end)

      assert length(target_accounts_uuids) == 1
      assert Enum.member?(target_accounts_uuids, account.uuid)
      refute Enum.member?(target_accounts_uuids, account_unlinked.uuid)
    end

    test "returns the list of accounts having rights on the user wallet" do
      user = insert(:user)
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_unlinked = insert(:account)
      {:ok, _} = AccountUser.link(account_1.uuid, user.uuid, %System{})
      {:ok, _} = AccountUser.link(account_2.uuid, user.uuid, %System{})

      wallet = insert(:wallet, user: user, account: nil)

      target_accounts_uuids =
        wallet |> WalletTarget.get_target_accounts(DispatchConfig) |> Enum.map(fn a -> a.uuid end)

      assert length(target_accounts_uuids) == 2
      assert Enum.member?(target_accounts_uuids, account_1.uuid)
      assert Enum.member?(target_accounts_uuids, account_2.uuid)
      refute Enum.member?(target_accounts_uuids, account_unlinked.uuid)
    end
  end
end
