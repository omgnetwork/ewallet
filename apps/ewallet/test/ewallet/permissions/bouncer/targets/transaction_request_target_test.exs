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

defmodule EWallet.Bouncer.TransactionRequestTargetTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWalletDB.AccountUser
  alias EWallet.Bouncer.{TransactionRequestTarget, DispatchConfig}
  alias ActivityLogger.System

  describe "get_owner_uuids/1" do
    test "returns the list of UUIDs owning the transaction request when user and account not nil" do
      account = insert(:account)
      user = insert(:user)

      transaction_request =
        insert(:transaction_request, %{account: account, user_uuid: user.uuid})

      res = TransactionRequestTarget.get_owner_uuids(transaction_request)
      assert res == [account.uuid, user.uuid]
    end

    test "returns the list of UUIDs owning the transaction request when user not nil" do
      user = insert(:user)
      transaction_request = insert(:transaction_request, %{account: nil, user_uuid: user.uuid})
      res = TransactionRequestTarget.get_owner_uuids(transaction_request)
      assert res == [user.uuid]
    end

    test "returns the list of UUIDs owning the transaction request when account not nil" do
      account = insert(:account)
      transaction_request = insert(:transaction_request, %{account: account, user_uuid: nil})
      res = TransactionRequestTarget.get_owner_uuids(transaction_request)
      assert res == [account.uuid]
    end
  end

  describe "get_target_types/0" do
    test "returns a list of types" do
      assert TransactionRequestTarget.get_target_types() == [
               :account_transaction_requests,
               :end_user_transaction_requests
             ]
    end
  end

  describe "get_target_type/1" do
    test "returns the type of the given transaction request when user is nil" do
      account = insert(:account)
      wallet = insert(:wallet, %{account: account, user: nil})

      transaction_request =
        insert(:transaction_request, %{wallet: wallet, user: nil, account: account})

      assert TransactionRequestTarget.get_target_type(transaction_request) ==
               :account_transaction_requests
    end

    test "returns the type of the given transaction request when user is not nil" do
      user = insert(:user)
      wallet = insert(:wallet, %{account: nil, user: user})

      transaction_request =
        insert(:transaction_request, %{wallet: wallet, user_uuid: user.uuid, account: nil})

      assert TransactionRequestTarget.get_target_type(transaction_request) ==
               :end_user_transaction_requests
    end
  end

  describe "get_target_accounts/2" do
    test "returns the list of accounts having rights on the transaction request when user is nil" do
      account = insert(:account)
      transaction_request = insert(:transaction_request, %{account: account, user_uuid: nil})

      target_accounts_uuids =
        transaction_request
        |> TransactionRequestTarget.get_target_accounts(DispatchConfig)
        |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(target_accounts_uuids, account.uuid)
    end

    test "returns the list of accounts having rights on the transaction request when user is not nil" do
      user = insert(:user)
      account = insert(:account)
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

      transaction_request = insert(:transaction_request, user_uuid: user.uuid)

      target_accounts_uuids =
        transaction_request
        |> TransactionRequestTarget.get_target_accounts(DispatchConfig)
        |> Enum.map(fn a -> a.uuid end)

      assert Enum.member?(target_accounts_uuids, account.uuid)
    end
  end
end
