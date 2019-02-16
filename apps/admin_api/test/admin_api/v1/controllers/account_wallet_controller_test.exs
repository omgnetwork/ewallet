# Copyright 2019 OmiseGO Pte Ltd
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

defmodule AdminAPI.V1.AccountWalletControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWalletDB.{Account, User}

  describe "/account.get_wallets_and_user_wallets" do
    test_with_auths "returns a list of wallets and pagination data for the specified account" do
      account = Account.get_master_account()
      {:ok, account_1} = :account |> params_for() |> Account.insert()
      {:ok, account_2} = :account |> params_for() |> Account.insert()

      response = request("/account.get_wallets_and_user_wallets", %{"id" => account.id})

      # Asserts return data
      assert response["success"]
      assert response["data"]["object"] == "list"
      assert is_list(response["data"]["data"])

      wallets = response["data"]["data"]
      # 6 account wallets + 1 user wallet
      assert length(wallets) == 7

      wallets =
        Enum.map(wallets, fn wallet ->
          {wallet["account_id"], wallet["identifier"]}
        end)

      assert Enum.member?(wallets, {account.id, "primary"})
      assert Enum.member?(wallets, {account.id, "burn"})
      assert Enum.member?(wallets, {account_1.id, "primary"})
      assert Enum.member?(wallets, {account_1.id, "burn"})
      assert Enum.member?(wallets, {account_2.id, "primary"})
      assert Enum.member?(wallets, {account_2.id, "burn"})

      # Asserts pagination data
      pagination = response["data"]["pagination"]
      assert is_integer(pagination["per_page"])
      assert is_integer(pagination["current_page"])
      assert is_boolean(pagination["is_last_page"])
      assert is_boolean(pagination["is_first_page"])
    end

    test_with_auths "returns a list of wallets and pagination data for the specified account with owned = true" do
      account = Account.get_master_account()
      {:ok, _account_1} = :account |> params_for() |> Account.insert()
      {:ok, _account_2} = :account |> params_for() |> Account.insert()

      response =
        request("/account.get_wallets_and_user_wallets", %{
          "id" => account.id,
          "owned" => true
        })

      # Asserts return data
      assert response["success"]
      assert response["data"]["object"] == "list"
      assert is_list(response["data"]["data"])

      wallets = response["data"]["data"]
      assert length(wallets) == 3

      wallets =
        Enum.map(wallets, fn wallet ->
          {wallet["account_id"], wallet["identifier"]}
        end)

      assert Enum.member?(wallets, {account.id, "primary"})
      assert Enum.member?(wallets, {account.id, "burn"})

      # Asserts pagination data
      pagination = response["data"]["pagination"]
      assert is_integer(pagination["per_page"])
      assert is_integer(pagination["current_page"])
      assert is_boolean(pagination["is_last_page"])
      assert is_boolean(pagination["is_first_page"])
    end

    test_with_auths "returns a list of wallets according to sort_by and sort_direction" do
      user = get_test_user()
      user_wallet = User.get_primary_wallet(user)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account, parent: account_2)

      _account_1_wallet_1 =
        insert(:wallet, %{
          account: account_1,
          address: "aaaa111111111111",
          identifier: "secondary_1"
        })

      account_2_wallet_1 =
        insert(:wallet, %{
          account: account_2,
          address: "aaaa333333333333",
          identifier: "secondary_2"
        })

      account_3_wallet_1 =
        insert(:wallet, %{
          account: account_3,
          address: "aaaa222222222222",
          identifier: "secondary_3"
        })

      account_3_wallet_2 =
        insert(:wallet, %{
          account: account_3,
          address: "bbbb111111111111",
          identifier: "secondary_4"
        })

      attrs = %{
        "id" => account_2.id,
        # Search is case-insensitive
        "sort_by" => "address",
        "sort_dir" => "desc"
      }

      response = request("/account.get_wallets_and_user_wallets", attrs)
      wallets = response["data"]["data"]

      assert response["success"]
      # account 2's wallet + one user's wallet + 2 wallets from account 3
      assert Enum.count(wallets) == 4

      ordered_addresses =
        [
          user_wallet.address,
          account_2_wallet_1.address,
          account_3_wallet_1.address,
          account_3_wallet_2.address
        ]
        |> Enum.sort()
        |> Enum.reverse()

      assert Enum.at(wallets, 0)["address"] == Enum.at(ordered_addresses, 0)
      assert Enum.at(wallets, 1)["address"] == Enum.at(ordered_addresses, 1)
      assert Enum.at(wallets, 2)["address"] == Enum.at(ordered_addresses, 2)
      assert Enum.at(wallets, 3)["address"] == Enum.at(ordered_addresses, 3)

      wallets =
        Enum.map(wallets, fn wallet ->
          {wallet["account_id"], wallet["identifier"]}
        end)

      assert Enum.member?(wallets, {account_2.id, "secondary_2"})
      assert Enum.member?(wallets, {account_3.id, "secondary_3"})
      assert Enum.member?(wallets, {account_3.id, "secondary_4"})
    end

    test_with_auths "returns :invalid_parameter error when id is not given" do
      response = request("/account.get_wallets_and_user_wallets", %{})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided. `id` is required."
    end
  end

  describe "/account.get_wallets" do
    test_with_auths "returns a list of wallets and pagination data for the specified account" do
      account = Account.get_master_account()
      {:ok, account_1} = :account |> params_for() |> Account.insert()
      {:ok, account_2} = :account |> params_for() |> Account.insert()

      response = request("/account.get_wallets", %{"id" => account.id})

      # Asserts return data
      assert response["success"]
      assert response["data"]["object"] == "list"
      assert is_list(response["data"]["data"])

      wallets = response["data"]["data"]
      assert length(wallets) == 6

      wallets =
        Enum.map(wallets, fn wallet ->
          {wallet["account_id"], wallet["identifier"]}
        end)

      assert Enum.member?(wallets, {account.id, "primary"})
      assert Enum.member?(wallets, {account.id, "burn"})
      assert Enum.member?(wallets, {account_1.id, "primary"})
      assert Enum.member?(wallets, {account_1.id, "burn"})
      assert Enum.member?(wallets, {account_2.id, "primary"})
      assert Enum.member?(wallets, {account_2.id, "burn"})

      # Asserts pagination data
      pagination = response["data"]["pagination"]
      assert is_integer(pagination["per_page"])
      assert is_integer(pagination["current_page"])
      assert is_boolean(pagination["is_last_page"])
      assert is_boolean(pagination["is_first_page"])
    end

    test_with_auths "returns a list of wallets and pagination data for the specified account with owned = true" do
      account = Account.get_master_account()
      {:ok, _account_1} = :account |> params_for() |> Account.insert()
      {:ok, _account_2} = :account |> params_for() |> Account.insert()

      response =
        request("/account.get_wallets", %{
          "id" => account.id,
          "owned" => true
        })

      # Asserts return data
      assert response["success"]
      assert response["data"]["object"] == "list"
      assert is_list(response["data"]["data"])

      wallets = response["data"]["data"]
      assert length(wallets) == 2

      wallets =
        Enum.map(wallets, fn wallet ->
          {wallet["account_id"], wallet["identifier"]}
        end)

      assert Enum.member?(wallets, {account.id, "primary"})
      assert Enum.member?(wallets, {account.id, "burn"})

      # Asserts pagination data
      pagination = response["data"]["pagination"]
      assert is_integer(pagination["per_page"])
      assert is_integer(pagination["current_page"])
      assert is_boolean(pagination["is_last_page"])
      assert is_boolean(pagination["is_first_page"])
    end

    test_with_auths "returns a list of wallets according to sort_by and sort_direction" do
      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account, parent: account_2)

      _account_1_wallet_1 =
        insert(:wallet, %{
          account: account_1,
          address: "aaaa111111111111",
          identifier: "secondary_1"
        })

      account_2_wallet_1 =
        insert(:wallet, %{
          account: account_2,
          address: "aaaa333333333333",
          identifier: "secondary_2"
        })

      account_3_wallet_1 =
        insert(:wallet, %{
          account: account_3,
          address: "aaaa222222222222",
          identifier: "secondary_3"
        })

      account_3_wallet_2 =
        insert(:wallet, %{
          account: account_3,
          address: "bbbb111111111111",
          identifier: "secondary_4"
        })

      attrs = %{
        "id" => account_2.id,
        # Search is case-insensitive
        "sort_by" => "address",
        "sort_dir" => "desc"
      }

      response = request("/account.get_wallets", attrs)
      wallets = response["data"]["data"]

      assert response["success"]
      # account 2's wallet + 2 wallets from account 3
      assert Enum.count(wallets) == 3

      ordered_addresses =
        [
          account_2_wallet_1.address,
          account_3_wallet_1.address,
          account_3_wallet_2.address
        ]
        |> Enum.sort()
        |> Enum.reverse()

      assert Enum.at(wallets, 0)["address"] == Enum.at(ordered_addresses, 0)
      assert Enum.at(wallets, 1)["address"] == Enum.at(ordered_addresses, 1)
      assert Enum.at(wallets, 2)["address"] == Enum.at(ordered_addresses, 2)

      wallets =
        Enum.map(wallets, fn wallet ->
          {wallet["account_id"], wallet["identifier"]}
        end)

      assert Enum.member?(wallets, {account_2.id, "secondary_2"})
      assert Enum.member?(wallets, {account_3.id, "secondary_3"})
      assert Enum.member?(wallets, {account_3.id, "secondary_4"})
    end

    test_with_auths "returns :invalid_parameter error when id is not given" do
      response = request("/account.get_wallets", %{})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided. `id` is required."
    end
  end
end
