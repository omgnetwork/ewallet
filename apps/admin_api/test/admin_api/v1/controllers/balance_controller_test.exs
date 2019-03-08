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

defmodule AdminAPI.V1.BalanceControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWalletDB.{Account, Token, User}

  describe "/wallet.all_balances" do
    test_with_auths "returns a list of balances and pagination data when given an existing wallet address" do
      user_wallet = prepare_user_wallet()

      [omg, btc, _abc] = prepare_balances(user_wallet, [100, 200, 300])

      attrs = %{
        "sort_by" => "inserted_at",
        "sort_dir" => "asc",
        "per_page" => 2,
        "start_after" => nil,
        "start_by" => "id",
        "address" => user_wallet.address
      }

      response = request("/wallet.all_balances", attrs)
      token_ids = map_tokens_field(response, "id")

      assert response["success"] == true
      assert response["data"]["pagination"]["count"] == 2
      assert token_ids == [omg.id, btc.id]
    end

    test_with_auths "returns a list of balances and pagination data after given 'token_id'" do
      user_wallet = prepare_user_wallet()

      [omg, btc, _abc] = prepare_balances(user_wallet, [100, 200, 300])

      attrs = %{
        "sort_by" => "inserted_at",
        "sort_dir" => "asc",
        "per_page" => 1,
        "start_after" => omg.id,
        "start_by" => "id",
        "address" => user_wallet.address
      }

      response = request("/wallet.all_balances", attrs)
      token_ids = map_tokens_field(response, "id")

      assert response["success"] == true
      assert token_ids == [btc.id]
    end

    test_with_auths "returns a list of balances with correct amount" do
      user_wallet = prepare_user_wallet()

      [omg, btc, eth] = prepare_balances(user_wallet, [100, 200, 300])

      attrs = %{
        "sort_by" => "inserted_at",
        "sort_dir" => "asc",
        "per_page" => 3,
        "start_after" => nil,
        "start_by" => "id",
        "address" => user_wallet.address
      }

      response = request("/wallet.all_balances", attrs)

      amounts = map_balances_field(response, "amount")
      token_ids = map_tokens_field(response, "id")
      [omg_subunit, btc_subunit, eth_subunit] = map_tokens_field(response, "subunit_to_unit")

      assert response["success"] == true
      assert token_ids == [omg.id, btc.id, eth.id]
      assert amounts == [100 * omg_subunit, 200 * btc_subunit, 300 * eth_subunit]
    end

    test_with_auths "returns :error when given non-existing wallet address" do
      user_wallet = prepare_user_wallet()

      prepare_balances(user_wallet, [100, 200, 300])

      attrs = %{
        "sort_by" => "inserted_at",
        "sort_dir" => "asc",
        "start_after" => nil,
        "start_by" => "id",
        "address" => "qwertyuiop"
      }

      response = request("/wallet.all_balances", attrs)

      assert response["success"] == false
      assert response["data"]["code"] == "unauthorized"

      assert response["data"]["description"] ==
               "You are not allowed to perform the requested operation."
    end

    test_with_auths "returns :error when missing wallet address" do
      attrs = %{
        "sort_by" => "inserted_at",
        "sort_dir" => "asc",
        "start_after" => nil,
        "start_by" => "id"
      }

      response = request("/wallet.all_balances", attrs)

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `address` is required."
    end
  end

  # number of created tokens == number of given amounts
  defp prepare_balances(user_wallet, amounts) do
    account = Account.get_master_account()
    master_wallet = Account.get_primary_wallet(account)

    amounts
    |> Enum.reduce([], fn amount, acc ->
      [do_prepare_balances(master_wallet, user_wallet, amount) | acc]
    end)
    |> Enum.reverse()
  end

  defp do_prepare_balances(master_wallet, user_wallet, amount) do
    # Create and mint token
    {:ok, token} = :token |> params_for() |> Token.insert()

    mint!(token)

    # Transfer balance from master_wallet to user_wallet by given amount
    transfer!(master_wallet.address, user_wallet.address, token, amount * token.subunit_to_unit)

    token
  end

  defp prepare_user_wallet do
    {:ok, user} = :user |> params_for() |> User.insert()
    User.get_primary_wallet(user)
  end

  defp map_tokens_field(response, field) do
    Enum.map(response["data"]["data"], fn balance -> balance["token"][field] end)
  end

  defp map_balances_field(response, field) do
    Enum.map(response["data"]["data"], fn balance -> balance[field] end)
  end
end
