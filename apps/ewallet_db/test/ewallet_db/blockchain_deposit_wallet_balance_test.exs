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

defmodule EWalletDB.BlockchainDepositWalletBalanceTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias EWallet.BlockchainHelper
  alias EWalletDB.BlockchainDepositWalletBalance

  describe "all_for_token/2" do
    test "returns the list of all blockchain deposit wallet balances for the given token" do
      token = insert(:token)
      b1 = insert(:blockchain_deposit_wallet_balance, token: token)
      b2 = insert(:blockchain_deposit_wallet_balance)
      b3 = insert(:blockchain_deposit_wallet_balance, token: token)
      b4 = insert(:blockchain_deposit_wallet_balance)

      balances =
        BlockchainDepositWalletBalance.all_for_token(
          token,
          BlockchainHelper.rootchain_identifier()
        )

      assert Enum.any?(balances, fn b -> b.uuid == b1.uuid end)
      refute Enum.any?(balances, fn b -> b.uuid == b2.uuid end)
      assert Enum.any?(balances, fn b -> b.uuid == b3.uuid end)
      refute Enum.any?(balances, fn b -> b.uuid == b4.uuid end)
    end

    test "returns the list of all blockchain deposit wallet balances for the given tokens" do
      token_1 = insert(:token)
      token_2 = insert(:token)
      b1 = insert(:blockchain_deposit_wallet_balance, token: token_1)
      b2 = insert(:blockchain_deposit_wallet_balance)
      b3 = insert(:blockchain_deposit_wallet_balance, token: token_2)
      b4 = insert(:blockchain_deposit_wallet_balance)

      balances =
        BlockchainDepositWalletBalance.all_for_token(
          [token_1, token_2],
          BlockchainHelper.rootchain_identifier()
        )

      assert Enum.any?(balances, fn b -> b.uuid == b1.uuid end)
      refute Enum.any?(balances, fn b -> b.uuid == b2.uuid end)
      assert Enum.any?(balances, fn b -> b.uuid == b3.uuid end)
      refute Enum.any?(balances, fn b -> b.uuid == b4.uuid end)
    end
  end

  describe "create_or_update_all/2" do
    test "inserts the balances with the given wallet address and balances" do
      wallet = insert(:blockchain_deposit_wallet)
      token_1 = insert(:token)
      token_2 = insert(:token)

      balance_data = [
        %{token: token_1, amount: 100},
        %{token: token_2, amount: 200}
      ]

      balances =
        BlockchainDepositWalletBalance.create_or_update_all(
          wallet.address,
          balance_data,
          BlockchainHelper.rootchain_identifier()
        )

      assert Enum.all?(balances, fn {:ok, b} ->
               b.blockchain_deposit_wallet_address == wallet.address
             end)

      assert Enum.any?(balances, fn {:ok, b} ->
               b.token_uuid == token_1.uuid && b.amount == 100
             end)

      assert Enum.any?(balances, fn {:ok, b} ->
               b.token_uuid == token_2.uuid && b.amount == 200
             end)
    end

    test "updates the balances with the given wallet address and balances" do
      wallet = insert(:blockchain_deposit_wallet)
      token_1 = insert(:token)
      token_2 = insert(:token)

      _ =
        insert(:blockchain_deposit_wallet_balance,
          token: token_1,
          amount: 99,
          blockchain_deposit_wallet: wallet
        )

      _ =
        insert(:blockchain_deposit_wallet_balance,
          token: token_2,
          amount: 99,
          blockchain_deposit_wallet: wallet
        )

      balance_data = [
        %{token: token_1, amount: 100},
        %{token: token_2, amount: 200}
      ]

      balances =
        BlockchainDepositWalletBalance.create_or_update_all(
          wallet.address,
          balance_data,
          BlockchainHelper.rootchain_identifier()
        )

      assert Enum.all?(balances, fn {:ok, b} ->
               b.blockchain_deposit_wallet_address == wallet.address
             end)

      assert Enum.any?(balances, fn {:ok, b} ->
               b.token_uuid == token_1.uuid && b.amount == 100
             end)

      assert Enum.any?(balances, fn {:ok, b} ->
               b.token_uuid == token_2.uuid && b.amount == 200
             end)
    end
  end
end
