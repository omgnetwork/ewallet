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

defmodule EWallet.Web.BalanceLoaderTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Web.Paginator
  alias EWallet.Web.BalanceLoader
  alias EWalletDB.{Account, Token, User}

  describe "add_balances/1" do
    test "returns a wallet with a list of balances of all tokens when given wallet" do
      user_wallet = prepare_user_wallet()
      [omg, btc, eth] = prepare_balances(user_wallet, [100, 200, 300])

      assert {:ok, wallet} = BalanceLoader.add_balances(user_wallet)

      assert user_wallet == Map.drop(wallet, [:balances])
      assert [balance_omg, balance_btc, balance_eth] = wallet.balances

      assert balance_omg = %{
               "object" => "balance",
               "token" => omg,
               "amount" => 100 * omg.subunit_to_unit
             }

      assert balance_btc = %{
               "object" => "balance",
               "token" => btc,
               "amount" => 200 * btc.subunit_to_unit
             }

      assert balance_eth = %{
               "object" => "balance",
               "token" => eth,
               "amount" => 300 * eth.subunit_to_unit
             }
    end

    test "returns a list of balances of all tokens when given paginated wallet" do
      user_wallet = prepare_user_wallet()
      [omg, btc, eth] = prepare_balances(user_wallet, [100, 200, 300])

      paged_wallets = %Paginator{
        data: [user_wallet],
        pagination: %{
          current_page: 1,
          per_page: 10,
          is_first_page: true,
          is_last_page: true
        }
      }

      assert %Paginator{data: [wallet], pagination: pagination} =
               BalanceLoader.add_balances(paged_wallets)

      assert pagination == paged_wallets.pagination

      assert wallet.balances == [
               %{
                 token: omg,
                 amount: 100 * omg.subunit_to_unit
               },
               %{
                 token: btc,
                 amount: 200 * btc.subunit_to_unit
               },
               %{
                 token: eth,
                 amount: 300 * eth.subunit_to_unit
               }
             ]

      assert user_wallet == Map.drop(wallet, [:balances])
    end
  end

  describe "add_balances/2" do
    test "returns a list of balances of given tokens when given wallet and non-empty tokens" do
      user_wallet = prepare_user_wallet()
      [omg, btc, _abc] = prepare_balances(user_wallet, [100, 200, 300])

      assert {:ok, balances} = BalanceLoader.add_balances(user_wallet, [omg, btc])

      assert [balance_omg, balance_btc] = balances

      assert balance_omg == %{token: omg, amount: 100 * omg.subunit_to_unit}
      assert balance_btc == %{token: btc, amount: 200 * btc.subunit_to_unit}
    end

    test "returns an empty list when given wallet and empty tokens" do
      user_wallet = prepare_user_wallet()
      [_token_1, _token_2, _token_3] = prepare_balances(user_wallet, [100, 200, 300])

      assert {:ok, balances} = BalanceLoader.add_balances(user_wallet, [])

      assert balances == []
    end
  end

  # number of created tokens == number of given amounts
  defp prepare_balances(user_wallet, amounts) do
    account = Account.get_master_account()
    master_wallet = Account.get_primary_wallet(account)

    amounts
    |> Enum.reduce(
      [],
      fn amount, acc ->
        [do_prepare_balances(master_wallet, user_wallet, amount) | acc]
      end
    )
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
end
