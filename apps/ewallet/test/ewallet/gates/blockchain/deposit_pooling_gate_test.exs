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

defmodule EWallet.DepositPoolingGateTest do
  use EWallet.DBCase, async: false
  import EWalletDB.Factory
  alias ActivityLogger.System
  alias EWallet.{DepositPoolingGate, BlockchainDepositWalletGate}

  alias EWalletDB.{
    BlockchainWallet,
    BlockchainHDWallet
  }

  describe "move_deposits_to_pooled_funds/2" do
    test "pools the funds if a deposit wallet reaches the threshold" do
      blockchain_identifier = "ethereum"
      hd_wallet = BlockchainHDWallet.get_primary()

      token =
        insert(:token,
          blockchain_identifier: blockchain_identifier,
          blockchain_address: "0x0000000000000000000000000000000000000000"
        )

      # wallet = insert(:wallet)
      # {:ok, wallet} =
      #   BlockchainDepositWalletGate.get_or_generate(wallet, %{"originator" => %System{}})
      # [{:ok, _}] =
      #   BlockchainDepositWalletGate.store_balances(deposit_wallet_balance.blockchain_deposit_wallet_address, blockchain_identifier, [token])

      deposit_wallet =
        insert(:blockchain_deposit_wallet,
          blockchain_identifier: blockchain_identifier,
          blockchain_hd_wallet_uuid: hd_wallet.uuid
        )

      deposit_wallet_balance =
        insert(:blockchain_deposit_wallet_balance,
          token: token,
          amount: 100_000_000_000_000_000_000_000,
          blockchain_identifier: blockchain_identifier,
          blockchain_deposit_wallet: deposit_wallet
        )

      hot_wallet = BlockchainWallet.get_primary_hot_wallet(blockchain_identifier)

      assert {:ok, [{:ok, _transaction}]} =
               DepositPoolingGate.move_deposits_to_pooled_funds(blockchain_identifier)
    end

    test "avoids pooling funds that have a pooling transaction in progress"

    test "keeps the deposit wallets' funds intact if none reaches the threshold"
  end
end
