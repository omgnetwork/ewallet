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
  alias EWallet.{DepositPoolingGate, TransactionRegistry}
  alias EWalletDB.{BlockchainHDWallet, BlockchainWallet, TransactionState}

  describe "move_deposits_to_pooled_funds/2" do
    test "pools the funds if a deposit wallet reaches the threshold" do
      blockchain_identifier = "ethereum"
      hot_wallet = BlockchainWallet.get_primary_hot_wallet(blockchain_identifier)

      token =
        insert(:token,
          blockchain_identifier: blockchain_identifier,
          blockchain_address: "0x0000000000000000000000000000000000000000",
          subunit_to_unit: 1_000_000_000_000_000_000
        )

      deposit_wallet =
        insert(:blockchain_deposit_wallet,
          blockchain_identifier: blockchain_identifier,
          blockchain_hd_wallet_uuid: BlockchainHDWallet.get_primary().uuid
        )

      balance =
        insert(:blockchain_deposit_wallet_balance,
          token: token,
          amount: 100 * token.subunit_to_unit,
          blockchain_identifier: blockchain_identifier,
          blockchain_deposit_wallet: deposit_wallet
        )

      assert {:ok, [{:ok, txn}]} =
               DepositPoolingGate.move_deposits_to_pooled_funds(blockchain_identifier)

      assert txn.from_blockchain_wallet_address == nil
      assert txn.from_deposit_wallet_address == deposit_wallet.address

      assert txn.amount == balance.amount - txn.gas_price * txn.gas_limit
      assert txn.token_uuid == token.uuid

      assert txn.to_blockchain_wallet_address == hot_wallet.address
      assert txn.to_deposit_wallet_address == nil

      # For this test, we only care that the transaction is submitted,
      # what happens after that is out of the scope of this module,
      # so we can stop the tracker immediately.
      {:ok, %{pid: tracker_pid}} = TransactionRegistry.lookup(txn.uuid)
      :ok = GenServer.stop(tracker_pid)
    end

    test "avoids pooling funds that have a pooling transaction in progress" do
      blockchain_identifier = "ethereum"

      token =
        insert(:token,
          blockchain_identifier: blockchain_identifier,
          blockchain_address: "0x0000000000000000000000000000000000000000",
          subunit_to_unit: 1_000_000_000_000_000_000
        )

      deposit_wallet =
        insert(:blockchain_deposit_wallet,
          blockchain_identifier: blockchain_identifier,
          blockchain_hd_wallet_uuid: BlockchainHDWallet.get_primary().uuid
        )

      balance =
        insert(:blockchain_deposit_wallet_balance,
          token: token,
          amount: 200 * token.subunit_to_unit,
          blockchain_identifier: blockchain_identifier,
          blockchain_deposit_wallet: deposit_wallet
        )

      pooling_txn =
        insert(
          :deposit_transaction,
          blockchain_identifier: blockchain_identifier,
          status: TransactionState.pending_confirmations(),
          from_deposit_wallet_address: deposit_wallet.address,
          token: token,
          amount: 100 * token.subunit_to_unit
        )

      assert {:ok, [{:ok, txn}]} =
               DepositPoolingGate.move_deposits_to_pooled_funds(blockchain_identifier)

      assert txn.amount == balance.amount - pooling_txn.amount - txn.gas_price * txn.gas_limit

      # For this test, we only care that the transaction is submitted,
      # what happens after that is out of the scope of this module,
      # so we can stop the tracker immediately.
      {:ok, %{pid: tracker_pid}} = TransactionRegistry.lookup(txn.uuid)
      :ok = GenServer.stop(tracker_pid)
    end

    test "keeps the deposit wallets' funds intact if none reaches the threshold" do
      blockchain_identifier = "ethereum"

      token =
        insert(:token,
          blockchain_identifier: blockchain_identifier,
          blockchain_address: "0x0000000000000000000000000000000000000000",
          subunit_to_unit: 1_000_000_000_000_000_000
        )

      deposit_wallet =
        insert(:blockchain_deposit_wallet,
          blockchain_identifier: blockchain_identifier,
          blockchain_hd_wallet_uuid: BlockchainHDWallet.get_primary().uuid
        )

      _ =
        insert(:blockchain_deposit_wallet_balance,
          token: token,
          amount: 0,
          blockchain_identifier: blockchain_identifier,
          blockchain_deposit_wallet: deposit_wallet
        )

      assert {:ok, [{:skipped, :amount_too_low}]} =
               DepositPoolingGate.move_deposits_to_pooled_funds(blockchain_identifier)
    end
  end
end
