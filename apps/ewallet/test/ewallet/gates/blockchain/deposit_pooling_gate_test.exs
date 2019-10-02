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
  alias EthBlockchain.GasHelper
  alias EWallet.{DepositPoolingGate, TransactionTracker}
  alias EWalletDB.{BlockchainHDWallet, BlockchainWallet, Repo, TransactionState}

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
          blockchain_hd_wallet: BlockchainHDWallet.get_primary()
        )

      balance =
        insert(:blockchain_deposit_wallet_cached_balance,
          token: token,
          amount: 100 * token.subunit_to_unit,
          blockchain_identifier: blockchain_identifier,
          blockchain_deposit_wallet: deposit_wallet
        )

      gas_price = GasHelper.get_default_gas_price()
      gas_limit = GasHelper.get_default_gas_limit(:contract_transaction)

      assert {:ok, [dtxn]} =
               DepositPoolingGate.move_deposits_to_pooled_funds(blockchain_identifier)

      dtxn = Repo.preload(dtxn, :transaction)
      assert dtxn.from_blockchain_address == nil
      assert dtxn.from_deposit_wallet_address == deposit_wallet.address

      assert dtxn.amount == balance.amount - gas_price * gas_limit
      assert dtxn.token_uuid == token.uuid

      assert dtxn.to_blockchain_address == hot_wallet.address
      assert dtxn.to_deposit_wallet_address == nil

      # For this test, we only care that the transaction is submitted,
      # what happens after that is out of the scope of this module,
      # so we can stop the tracker immediately.
      {:ok, tracker_pid} = TransactionTracker.lookup(dtxn.transaction.uuid)
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
          blockchain_hd_wallet: BlockchainHDWallet.get_primary()
        )

      balance =
        insert(:blockchain_deposit_wallet_cached_balance,
          token: token,
          amount: 200 * token.subunit_to_unit,
          blockchain_identifier: blockchain_identifier,
          blockchain_deposit_wallet: deposit_wallet
        )

      pooling_txn =
        insert(
          :deposit_transaction,
          blockchain_identifier: blockchain_identifier,
          transaction: insert(:transaction, status: TransactionState.pending_confirmations()),
          from_deposit_wallet_address: deposit_wallet.address,
          token: token,
          amount: 100 * token.subunit_to_unit
        )

      gas_price = GasHelper.get_default_gas_price()
      gas_limit = GasHelper.get_default_gas_limit(:contract_transaction)

      assert {:ok, [dtxn]} =
               DepositPoolingGate.move_deposits_to_pooled_funds(blockchain_identifier)

      dtxn = Repo.preload(dtxn, :transaction)
      assert dtxn.amount == balance.amount - pooling_txn.amount - gas_price * gas_limit

      # For this test, we only care that the transaction is submitted,
      # what happens after that is out of the scope of this module,
      # so we can stop the tracker immediately.
      {:ok, tracker_pid} = TransactionTracker.lookup(dtxn.transaction.uuid)
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
          blockchain_hd_wallet: BlockchainHDWallet.get_primary()
        )

      _ =
        insert(:blockchain_deposit_wallet_cached_balance,
          token: token,
          amount: 0,
          blockchain_identifier: blockchain_identifier,
          blockchain_deposit_wallet: deposit_wallet
        )

      assert {:ok, []} =
               DepositPoolingGate.move_deposits_to_pooled_funds(blockchain_identifier)
    end
  end
end
