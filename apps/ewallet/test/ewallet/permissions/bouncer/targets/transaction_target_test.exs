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

defmodule EWallet.Bouncer.TransactionTargetTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWalletDB.{Transaction, AccountUser}
  alias EWallet.Bouncer.{TransactionTarget, DispatchConfig}
  alias ActivityLogger.System

  describe "get_owner_uuids/1" do
    test "returns the list of UUIDs owning the transaction when originated from a user" do
      user = insert(:user)
      transaction = insert(:transaction, %{from_user_uuid: user.uuid, from_account_uuid: nil})
      res = TransactionTarget.get_owner_uuids(transaction)
      assert res == [user.uuid]
    end

    test "returns the list of UUIDs owning the transaction when originated from an account" do
      account = insert(:account)
      transaction = insert(:transaction, %{from_user_uuid: nil, from_account_uuid: account.uuid})
      res = TransactionTarget.get_owner_uuids(transaction)
      assert res == [account.uuid]
    end
  end

  describe "get_target_types/0" do
    test "returns a list of types" do
      assert TransactionTarget.get_target_types() == [
               :account_transactions,
               :end_user_transactions
             ]
    end
  end

  describe "get_target_type/1" do
    test "returns the type of the given transaction when originated from a user" do
      user = insert(:user)
      transaction = insert(:transaction, %{from_user_uuid: user.uuid, from_account_uuid: nil})
      assert TransactionTarget.get_target_type(transaction) == :end_user_transactions
    end

    test "returns the type of the given transaction when targeted to a user" do
      user = insert(:user)
      transaction = insert(:transaction, %{to_user_uuid: user.uuid, to_account_uuid: nil})
      assert TransactionTarget.get_target_type(transaction) == :end_user_transactions
    end

    test "returns the type of the given transaction when originated and targeted to an account" do
      account = insert(:account)

      transaction =
        insert(:transaction, %{from_account_uuid: account.uuid, to_account_uuid: account.uuid})

      assert TransactionTarget.get_target_type(transaction) == :account_transactions
    end
  end

  describe "get_target_accounts/2" do
    test "returns the list of accounts having rights on the transaction when from and to are accounts" do
      account_from = insert(:account)
      account_to = insert(:account)
      account_unlinked = insert(:account)

      transaction =
        insert(:transaction, %{
          from_account_uuid: account_from.uuid,
          to_account_uuid: account_to.uuid
        })

      target_accounts_uuids =
        transaction
        |> TransactionTarget.get_target_accounts(DispatchConfig)
        |> Enum.map(fn a -> a.uuid end)

      assert length(target_accounts_uuids) == 2
      assert Enum.member?(target_accounts_uuids, account_from.uuid)
      assert Enum.member?(target_accounts_uuids, account_to.uuid)
      refute Enum.member?(target_accounts_uuids, account_unlinked.uuid)
    end

    test "returns the list of accounts having rights on the transaction when from account and to user" do
      account_from = insert(:account)

      user = insert(:user)
      account_user_1 = insert(:account)
      account_user_2 = insert(:account)
      account_unlinked = insert(:account)

      {:ok, _} = AccountUser.link(account_user_1.uuid, user.uuid, %System{})
      {:ok, _} = AccountUser.link(account_user_2.uuid, user.uuid, %System{})

      transaction =
        insert(:transaction, %{from_account_uuid: account_from.uuid, to_user_uuid: user.uuid})

      target_accounts_uuids =
        transaction
        |> TransactionTarget.get_target_accounts(DispatchConfig)
        |> Enum.map(fn a -> a.uuid end)

      assert length(target_accounts_uuids) == 3
      assert Enum.member?(target_accounts_uuids, account_from.uuid)
      assert Enum.member?(target_accounts_uuids, account_user_1.uuid)
      assert Enum.member?(target_accounts_uuids, account_user_2.uuid)
      refute Enum.member?(target_accounts_uuids, account_unlinked.uuid)
    end

    test "returns the list of accounts having rights on the transaction when from user and to account" do
      account_to = insert(:account)

      user = insert(:user)
      account_user_1 = insert(:account)
      account_user_2 = insert(:account)
      account_unlinked = insert(:account)

      {:ok, _} = AccountUser.link(account_user_1.uuid, user.uuid, %System{})
      {:ok, _} = AccountUser.link(account_user_2.uuid, user.uuid, %System{})

      transaction =
        insert(:transaction, %{to_account_uuid: account_to.uuid, from_user_uuid: user.uuid})

      target_accounts_uuids =
        transaction
        |> TransactionTarget.get_target_accounts(DispatchConfig)
        |> Enum.map(fn a -> a.uuid end)

      assert length(target_accounts_uuids) == 3
      assert Enum.member?(target_accounts_uuids, account_to.uuid)
      assert Enum.member?(target_accounts_uuids, account_user_1.uuid)
      assert Enum.member?(target_accounts_uuids, account_user_2.uuid)
      refute Enum.member?(target_accounts_uuids, account_unlinked.uuid)
    end

    test "returns the list of accounts having rights on the transaction when from user and to user" do
      user_from = insert(:user)
      account_user_from_1 = insert(:account)
      account_user_from_2 = insert(:account)

      user_to = insert(:user)
      account_user_to = insert(:account)
      account_user_from_and_to = insert(:account)

      account_unlinked = insert(:account)

      {:ok, _} = AccountUser.link(account_user_from_1.uuid, user_from.uuid, %System{})
      {:ok, _} = AccountUser.link(account_user_from_2.uuid, user_from.uuid, %System{})
      {:ok, _} = AccountUser.link(account_user_to.uuid, user_to.uuid, %System{})
      {:ok, _} = AccountUser.link(account_user_from_and_to.uuid, user_from.uuid, %System{})
      {:ok, _} = AccountUser.link(account_user_from_and_to.uuid, user_to.uuid, %System{})

      transaction =
        insert(:transaction, %{to_user_uuid: user_to.uuid, from_user_uuid: user_from.uuid})

      target_accounts_uuids =
        transaction
        |> TransactionTarget.get_target_accounts(DispatchConfig)
        |> Enum.map(fn a -> a.uuid end)

      assert length(target_accounts_uuids) == 4
      assert Enum.member?(target_accounts_uuids, account_user_from_1.uuid)
      assert Enum.member?(target_accounts_uuids, account_user_from_2.uuid)
      assert Enum.member?(target_accounts_uuids, account_user_to.uuid)
      assert Enum.member?(target_accounts_uuids, account_user_from_and_to.uuid)
      refute Enum.member?(target_accounts_uuids, account_unlinked.uuid)
    end

    test "returns the list of accounts having rights on the unsaved transaction when from a user address" do
      user = insert(:user)
      wallet = insert(:wallet, user: user)
      account_user_1 = insert(:account)
      account_user_2 = insert(:account)
      account_unlinked = insert(:account)

      {:ok, _} = AccountUser.link(account_user_1.uuid, user.uuid, %System{})
      {:ok, _} = AccountUser.link(account_user_2.uuid, user.uuid, %System{})

      transaction = %Transaction{from: wallet.address}

      target_accounts_uuids =
        transaction
        |> TransactionTarget.get_target_accounts(DispatchConfig)
        |> Enum.map(fn a -> a.uuid end)

      assert length(target_accounts_uuids) == 2
      assert Enum.member?(target_accounts_uuids, account_user_1.uuid)
      assert Enum.member?(target_accounts_uuids, account_user_2.uuid)
      refute Enum.member?(target_accounts_uuids, account_unlinked.uuid)
    end

    test "returns the list of accounts having rights on the unsaved transaction when from an account address" do
      account = insert(:account)
      account_unlinked = insert(:account)
      wallet = insert(:wallet, %{account: account, user: nil})

      transaction = %Transaction{from: wallet.address}

      target_accounts_uuids =
        transaction
        |> TransactionTarget.get_target_accounts(DispatchConfig)
        |> Enum.map(fn a -> a.uuid end)

      assert length(target_accounts_uuids) == 1
      assert Enum.member?(target_accounts_uuids, account.uuid)
      refute Enum.member?(target_accounts_uuids, account_unlinked.uuid)
    end

    test "returns the list of accounts having rights on the unsaved transaction when from an account uuid" do
      account = insert(:account)
      account_unlinked = insert(:account)

      transaction = %Transaction{from_account_uuid: account.uuid}

      target_accounts_uuids =
        transaction
        |> TransactionTarget.get_target_accounts(DispatchConfig)
        |> Enum.map(fn a -> a.uuid end)

      assert length(target_accounts_uuids) == 1
      assert Enum.member?(target_accounts_uuids, account.uuid)
      refute Enum.member?(target_accounts_uuids, account_unlinked.uuid)
    end

    test "returns the list of accounts having rights on the unsaved transaction when from a user uuid" do
      user = insert(:user)
      account_user_1 = insert(:account)
      account_user_2 = insert(:account)
      account_unlinked = insert(:account)

      {:ok, _} = AccountUser.link(account_user_1.uuid, user.uuid, %System{})
      {:ok, _} = AccountUser.link(account_user_2.uuid, user.uuid, %System{})

      transaction = %Transaction{from_user_uuid: user.uuid}

      target_accounts_uuids =
        transaction
        |> TransactionTarget.get_target_accounts(DispatchConfig)
        |> Enum.map(fn a -> a.uuid end)

      assert length(target_accounts_uuids) == 2
      assert Enum.member?(target_accounts_uuids, account_user_1.uuid)
      assert Enum.member?(target_accounts_uuids, account_user_2.uuid)
      refute Enum.member?(target_accounts_uuids, account_unlinked.uuid)
    end
  end
end
