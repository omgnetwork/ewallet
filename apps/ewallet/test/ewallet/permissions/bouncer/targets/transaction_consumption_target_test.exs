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

defmodule EWallet.Bouncer.TransactionConsumptionTargetTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWalletDB.AccountUser
  alias EWallet.Bouncer.{TransactionConsumptionTarget, DispatchConfig}
  alias ActivityLogger.System
  alias Utils.Helpers.UUID

  describe "get_owner_uuids/1" do
    test "returns the list of UUIDs owning the transaction consumption when user and account not nil" do
      account = insert(:account)
      user = insert(:user)

      transaction_consumption =
        insert(:transaction_consumption, %{account: account, user_uuid: user.uuid})

      res = TransactionConsumptionTarget.get_owner_uuids(transaction_consumption)
      assert res == [account.uuid, user.uuid]
    end

    test "returns the list of UUIDs owning the transaction consumption when user not nil" do
      user = insert(:user)

      transaction_consumption =
        insert(:transaction_consumption, %{account: nil, user_uuid: user.uuid})

      res = TransactionConsumptionTarget.get_owner_uuids(transaction_consumption)
      assert res == [user.uuid]
    end

    test "returns the list of UUIDs owning the transaction consumption when account not nil" do
      account = insert(:account)

      transaction_consumption =
        insert(:transaction_consumption, %{account: account, user_uuid: nil})

      res = TransactionConsumptionTarget.get_owner_uuids(transaction_consumption)
      assert res == [account.uuid]
    end
  end

  describe "get_target_types/0" do
    test "returns a list of types" do
      assert TransactionConsumptionTarget.get_target_types() == [
               :account_transaction_consumptions,
               :end_user_transaction_consumptions
             ]
    end
  end

  describe "get_target_type/1" do
    test "returns the type of the given transaction consumption when user is nil" do
      account = insert(:account)

      transaction_consumption =
        insert(:transaction_consumption, %{account: account, user_uuid: nil})

      assert TransactionConsumptionTarget.get_target_type(transaction_consumption) ==
               :account_transaction_consumptions
    end

    test "returns the type of the given transaction consumption when user is not nil" do
      user = insert(:user)
      transaction_consumption = insert(:transaction_consumption, user_uuid: user.uuid)

      assert TransactionConsumptionTarget.get_target_type(transaction_consumption) ==
               :end_user_transaction_consumptions
    end
  end

  describe "get_target_accounts/2" do
    test "returns the list of accounts having rights on the transaction consumption when user is nil" do
      account = insert(:account)

      transaction_consumption =
        insert(:transaction_consumption, %{account: account, user_uuid: nil})

      target_accounts_uuids =
        transaction_consumption
        |> TransactionConsumptionTarget.get_target_accounts(DispatchConfig)
        |> UUID.get_uuids()

      assert Enum.member?(target_accounts_uuids, account.uuid)
    end

    test "returns the list of accounts having rights on the transaction consumption when user is not nil" do
      user = insert(:user)
      account = insert(:account)
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

      transaction_consumption = insert(:transaction_consumption, user_uuid: user.uuid)

      target_accounts_uuids =
        transaction_consumption
        |> TransactionConsumptionTarget.get_target_accounts(DispatchConfig)
        |> UUID.get_uuids()

      assert Enum.member?(target_accounts_uuids, account.uuid)
    end
  end
end
