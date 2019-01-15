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

defmodule EWallet.BalanceFetcherTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.BalanceFetcher
  alias EWalletDB.{Account, Token, User}

  setup do
    account = Account.get_master_account()
    master_wallet = Account.get_primary_wallet(account)
    {:ok, user} = :user |> params_for() |> User.insert()
    user_wallet = User.get_primary_wallet(user)
    {:ok, btc} = :token |> params_for(symbol: "BTC") |> Token.insert()
    {:ok, omg} = :token |> params_for(symbol: "OMG") |> Token.insert()
    {:ok, knc} = :token |> params_for(symbol: "KNC") |> Token.insert()

    mint!(btc)
    mint!(omg)
    mint!(knc)

    %{
      master_wallet: master_wallet,
      user_wallet: user_wallet,
      user: user,
      btc: btc,
      omg: omg,
      knc: knc
    }
  end

  describe "all/1" do
    test "retrieve all balances from a user_id", context do
      transfer!(
        context.master_wallet.address,
        context.user_wallet.address,
        context.btc,
        990_000 * context.btc.subunit_to_unit
      )

      transfer!(
        context.master_wallet.address,
        context.user_wallet.address,
        context.omg,
        57_000 * context.omg.subunit_to_unit
      )

      {status, wallet} = BalanceFetcher.all(%{"user_id" => context.user.id})

      assert status == :ok
      assert wallet.address == context.user_wallet.address

      assert Enum.member?(wallet.balances, %{
               token: context.btc,
               amount: 990_000 * context.btc.subunit_to_unit
             })

      assert Enum.member?(wallet.balances, %{
               token: context.omg,
               amount: 57_000 * context.btc.subunit_to_unit
             })

      assert Enum.member?(wallet.balances, %{token: context.knc, amount: 0})
      assert Enum.count(wallet.balances) == 3
    end

    test "retrieve all balances from a provider_user_id", context do
      transfer!(
        context.master_wallet.address,
        context.user_wallet.address,
        context.btc,
        150_000 * context.btc.subunit_to_unit
      )

      transfer!(
        context.master_wallet.address,
        context.user_wallet.address,
        context.omg,
        12_000 * context.omg.subunit_to_unit
      )

      {status, wallet} =
        BalanceFetcher.all(%{"provider_user_id" => context.user.provider_user_id})

      assert status == :ok
      assert wallet.address == context.user_wallet.address

      assert Enum.member?(wallet.balances, %{
               token: context.btc,
               amount: 150_000 * context.btc.subunit_to_unit
             })

      assert Enum.member?(wallet.balances, %{
               token: context.omg,
               amount: 12_000 * context.btc.subunit_to_unit
             })

      assert Enum.member?(wallet.balances, %{token: context.knc, amount: 0})
      assert Enum.count(wallet.balances) == 3
    end

    test "retrieve all balances for a list of wallets", context do
      transfer!(
        context.master_wallet.address,
        context.user_wallet.address,
        context.btc,
        150_000 * context.btc.subunit_to_unit
      )

      transfer!(
        context.master_wallet.address,
        context.user_wallet.address,
        context.omg,
        12_000 * context.omg.subunit_to_unit
      )

      {status, wallets} =
        BalanceFetcher.all(%{
          "wallets" => [
            context.user_wallet,
            context.master_wallet
          ]
        })

      assert status == :ok

      wallet_1 = Enum.at(wallets, 0)
      wallet_2 = Enum.at(wallets, 1)

      assert wallet_1.address == context.user_wallet.address

      assert Enum.member?(wallet_1.balances, %{
               token: context.btc,
               amount: 150_000 * context.btc.subunit_to_unit
             })

      assert Enum.member?(wallet_1.balances, %{
               token: context.omg,
               amount: 12_000 * context.omg.subunit_to_unit
             })

      assert Enum.member?(wallet_1.balances, %{token: context.knc, amount: 0})
      assert Enum.count(wallet_1.balances) == 3

      assert wallet_2.address == context.master_wallet.address

      assert Enum.member?(wallet_2.balances, %{
               token: context.btc,
               amount: 850_000 * context.btc.subunit_to_unit
             })

      assert Enum.member?(wallet_2.balances, %{
               token: context.omg,
               amount: 988_000 * context.omg.subunit_to_unit
             })

      assert Enum.member?(wallet_2.balances, %{
               token: context.knc,
               amount: 1_000_000 * context.knc.subunit_to_unit
             })

      assert Enum.count(wallet_2.balances) == 3
    end

    test "retrieve all balances for a wallet", context do
      transfer!(
        context.master_wallet.address,
        context.user_wallet.address,
        context.btc,
        150_000 * context.btc.subunit_to_unit
      )

      transfer!(
        context.master_wallet.address,
        context.user_wallet.address,
        context.omg,
        12_000 * context.omg.subunit_to_unit
      )

      {status, wallet} = BalanceFetcher.all(%{"wallet" => context.user_wallet})

      assert status == :ok
      assert wallet.address == context.user_wallet.address

      assert Enum.member?(wallet.balances, %{
               token: context.btc,
               amount: 150_000 * context.btc.subunit_to_unit
             })

      assert Enum.member?(wallet.balances, %{
               token: context.omg,
               amount: 12_000 * context.btc.subunit_to_unit
             })

      assert Enum.member?(wallet.balances, %{token: context.knc, amount: 0})
      assert Enum.count(wallet.balances) == 3
    end
  end

  describe "get/2" do
    test "retrieve a specific balance from a token and an address", context do
      transfer!(
        context.master_wallet.address,
        context.user_wallet.address,
        context.btc,
        150_000 * context.btc.subunit_to_unit
      )

      transfer!(
        context.master_wallet.address,
        context.user_wallet.address,
        context.omg,
        12_000 * context.omg.subunit_to_unit
      )

      {status, wallet} = BalanceFetcher.get(context.omg.id, context.user_wallet)

      assert status == :ok
      assert wallet.address == context.user_wallet.address

      assert Enum.member?(wallet.balances, %{
               token: context.omg,
               amount: 12_000 * context.btc.subunit_to_unit
             })

      assert Enum.count(wallet.balances) == 1
    end
  end
end
