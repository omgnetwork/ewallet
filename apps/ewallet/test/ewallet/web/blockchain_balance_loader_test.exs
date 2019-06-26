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

defmodule EWallet.Web.BlockchainBalanceLoaderTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Web.BlockchainBalanceLoader

  describe "balances/2" do
    test "returns a list of balances of given tokens when given wallet address and non-empty tokens" do
      blockchain_wallet =
        insert(:blockchain_wallet, %{address: "0x0000000000000000000000000000000000000123"})

      token_1 =
        insert(:token, %{blockchain_address: "0x0000000000000000000000000000000000000000"})

      token_2 =
        insert(:token, %{blockchain_address: "0x0000000000000000000000000000000000000001"})

      _token_3 =
        insert(:token, %{blockchain_address: "0x0000000000000000000000000000000000000002"})

      assert {:ok, balances} =
               BlockchainBalanceLoader.balances(blockchain_wallet.address, [
                 token_1,
                 token_2
               ])

      assert [balance_token_1, balance_token_2] = balances

      assert balance_token_1 == %{token: token_1, amount: 123}
      assert balance_token_2 == %{token: token_2, amount: 123}
    end

    test "returns an empty list when given wallet and empty tokens" do
      blockchain_wallet =
        insert(:blockchain_wallet, %{address: "0x0000000000000000000000000000000000000123"})

      assert {:ok, balances} = BlockchainBalanceLoader.balances(blockchain_wallet.address, [])

      assert balances == []
    end
  end

  describe "wallet_balances/2" do
    test "returns a wallet with balances when given a wallet and tokens" do
      blockchain_wallet =
        insert(:blockchain_wallet, %{address: "0x0000000000000000000000000000000000000123"})

      token_1 =
        insert(:token, %{blockchain_address: "0x0000000000000000000000000000000000000000"})

      token_2 =
        insert(:token, %{blockchain_address: "0x0000000000000000000000000000000000000001"})

      assert {:ok, blockchain_wallet_with_balances} =
               BlockchainBalanceLoader.wallet_balances(blockchain_wallet, [token_1, token_2])

      assert blockchain_wallet_with_balances.address == blockchain_wallet.address
      assert [balance_token_1, balance_token_2] = blockchain_wallet_with_balances.balances
      assert balance_token_1 == %{token: token_1, amount: 123}
      assert balance_token_2 == %{token: token_2, amount: 123}
    end

    test "returns multiple wallets with balances when given multiple wallets and tokens" do
      blockchain_wallet_1 =
        insert(:blockchain_wallet, %{address: "0x0000000000000000000000000000000000000123"})

      blockchain_wallet_2 =
        insert(:blockchain_wallet, %{address: "0x0000000000000000000000000000000000000456"})

      token_1 =
        insert(:token, %{blockchain_address: "0x0000000000000000000000000000000000000000"})

      token_2 =
        insert(:token, %{blockchain_address: "0x0000000000000000000000000000000000000001"})

      wallets = [blockchain_wallet_1, blockchain_wallet_2]
      tokens = [token_1, token_2]

      assert {:ok, wallets_with_balances} =
               BlockchainBalanceLoader.wallet_balances(wallets, tokens)

      assert [wallet_with_balances_1, wallet_with_balances_2] = wallets_with_balances
      assert wallet_with_balances_1.address == blockchain_wallet_1.address
      assert wallet_with_balances_2.address == blockchain_wallet_2.address

      assert wallet_with_balances_1.balances == [
               %{token: token_1, amount: 123},
               %{token: token_2, amount: 123}
             ]

      assert wallet_with_balances_2.balances == [
               %{token: token_1, amount: 123},
               %{token: token_2, amount: 123}
             ]
    end
  end
end
