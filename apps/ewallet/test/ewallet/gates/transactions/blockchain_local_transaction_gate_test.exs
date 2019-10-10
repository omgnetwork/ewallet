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

defmodule EWallet.TransactionGate.BlockchainLocalTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias ActivityLogger.System
  alias EWallet.{MintGate, TransactionGate}
  alias EWalletDB.{Account, BlockchainWallet, BlockchainTransactionState, TransactionState}
  alias LocalLedgerDB.Factory, as: LedgerFactory

  setup do
    rootchain_identifier = Application.get_env(:ewallet_db, :rootchain_identifier)
    %{address: address} = BlockchainWallet.get_primary_hot_wallet(rootchain_identifier)

    master_account = Account.get_master_account()
    master_wallet = Account.get_primary_wallet(master_account)
    token = insert(:token)
    MintGate.mint_token(token, %{"amount" => 10000, "originator" => %System{}})

    %{hw_address: address, master_wallet: master_wallet, token: token}
  end

  describe "process_with_transaction/1 for transactions `from_ewallet_to_blockchain`" do
    test "confirms a transaction if the blockchain_transaction is confirmed", state do
      blockchain_transaction =
        insert(:blockchain_transaction_rootchain, status: BlockchainTransactionState.confirmed())

      transaction =
        insert(:transaction_with_blockchain,
          from_blockchain_address: state.hw_address,
          blockchain_transaction: blockchain_transaction
        )

      {:ok, transaction} =
        TransactionState.transition_to(
          :from_ewallet_to_blockchain,
          TransactionState.blockchain_submitted(),
          transaction,
          %{originator: %System{}}
        )

      assert transaction.status == TransactionState.blockchain_submitted()

      {res, txn_processed} = TransactionGate.BlockchainLocal.process_with_transaction(transaction)

      assert res == :ok
      assert txn_processed.status == TransactionState.confirmed()
    end

    test "returns the transaction untouched if it's already confirmed", state do
      transaction =
        insert(:transaction_with_blockchain, from_blockchain_address: state.hw_address)

      {:ok, transaction} =
        TransactionState.transition_to(
          :from_blockchain_to_ledger,
          TransactionState.confirmed(),
          transaction,
          %{originator: %System{}}
        )

      assert transaction.status == TransactionState.confirmed()

      {res, txn_processed} = TransactionGate.BlockchainLocal.process_with_transaction(transaction)

      assert res == :ok
      assert txn_processed == transaction
    end

    test "returns an error with the transaction untouched if an error code exists", state do
      transaction =
        insert(:transaction_with_blockchain, from_blockchain_address: state.hw_address)

      {:ok, transaction} =
        TransactionState.transition_to(
          :from_blockchain_to_ledger,
          TransactionState.failed(),
          transaction,
          %{error_code: "some_error", originator: %System{}}
        )

      assert transaction.status == TransactionState.failed()

      {res, txn_processed} = TransactionGate.BlockchainLocal.process_with_transaction(transaction)

      assert res == :error
      assert txn_processed == transaction
    end
  end

  describe "process_with_transaction/1 for transactions `from_ledger_to_blockchain`" do
    test "change the state of a transaction to `confirmed` when transaction is `blockchain_submitted` and blockchain transaction confirmed",
         state do
      blockchain_transaction =
        insert(:blockchain_transaction_rootchain, status: BlockchainTransactionState.confirmed())

      transaction =
        insert(:transaction_with_blockchain,
          from_blockchain_address: state.hw_address,
          from_wallet: state.master_wallet,
          from_token: state.token,
          to_token: state.token,
          local_ledger_uuid: LedgerFactory.insert(:entry).transaction_uuid,
          blockchain_transaction: blockchain_transaction,
          status: TransactionState.blockchain_submitted()
        )

      assert transaction.status == TransactionState.blockchain_submitted()

      {res, txn_processed} = TransactionGate.BlockchainLocal.process_with_transaction(transaction)

      assert res == :ok
      assert txn_processed.status == TransactionState.confirmed()
    end

    test "returns the transaction untouched if it's already confirmed", state do
      transaction =
        insert(:transaction_with_blockchain,
          from_blockchain_address: state.hw_address,
          from_wallet: state.master_wallet,
          status: TransactionState.confirmed()
        )

      assert transaction.status == TransactionState.confirmed()

      {res, txn_processed} = TransactionGate.BlockchainLocal.process_with_transaction(transaction)

      assert res == :ok
      assert txn_processed == transaction
    end

    test "returns an error with the transaction untouched if an error code exists", state do
      transaction =
        insert(:transaction_with_blockchain,
          from_blockchain_address: state.hw_address,
          from_wallet: state.master_wallet,
          status: TransactionState.failed(),
          error_code: "some_error"
        )

      assert transaction.status == TransactionState.failed()

      {res, txn_processed} = TransactionGate.BlockchainLocal.process_with_transaction(transaction)

      assert res == :error
      assert txn_processed == transaction
    end
  end

  describe "process_with_transaction/1 for transactions `from_blockchain_to_ewallet`" do
    test "confirms a transaction if the blockchain_transaction is confirmed", state do
      blockchain_transaction =
        insert(:blockchain_transaction_rootchain, status: BlockchainTransactionState.confirmed())

      transaction =
        insert(:transaction_with_blockchain,
          blockchain_transaction: blockchain_transaction,
          to_blockchain_address: state.hw_address
        )

      assert transaction.status == TransactionState.pending()

      {res, txn_processed} = TransactionGate.BlockchainLocal.process_with_transaction(transaction)

      assert res == :ok
      assert txn_processed.status == TransactionState.confirmed()
    end

    test "returns the transaction untouched if it's already confirmed", state do
      transaction =
        insert(:transaction_with_blockchain,
          to_blockchain_address: state.hw_address,
          status: TransactionState.confirmed()
        )

      assert transaction.status == TransactionState.confirmed()

      {res, txn_processed} = TransactionGate.BlockchainLocal.process_with_transaction(transaction)

      assert res == :ok
      assert txn_processed == transaction
    end

    test "returns an error with the transaction untouched if an error code exists", state do
      transaction =
        insert(:transaction_with_blockchain,
          to_blockchain_address: state.hw_address,
          status: TransactionState.failed(),
          error_code: "some_error"
        )

      assert transaction.status == TransactionState.failed()

      {res, txn_processed} = TransactionGate.BlockchainLocal.process_with_transaction(transaction)

      assert res == :error
      assert txn_processed == transaction
    end
  end

  describe "process_with_transaction/1 for transactions `from_blockchain_to_ledger`" do
    test "confirms a transaction if the blockchain_transaction is confirmed" do
      blockchain_transaction =
        insert(:blockchain_transaction_rootchain, status: BlockchainTransactionState.confirmed())

      transaction =
        insert(:transaction_with_blockchain,
          blockchain_transaction: blockchain_transaction,
          to_wallet: insert(:wallet)
        )

      assert transaction.status == TransactionState.pending()

      {res, txn_processed} = TransactionGate.BlockchainLocal.process_with_transaction(transaction)

      assert res == :ok
      assert txn_processed.status == TransactionState.confirmed()
    end

    test "returns the transaction untouched if it's already confirmed" do
      transaction =
        insert(:transaction_with_blockchain,
          to_wallet: insert(:wallet),
          status: TransactionState.confirmed()
        )

      assert transaction.status == TransactionState.confirmed()

      {res, txn_processed} = TransactionGate.BlockchainLocal.process_with_transaction(transaction)

      assert res == :ok
      assert txn_processed == transaction
    end

    test "returns an error with the transaction untouched if an error code exists" do
      transaction =
        insert(:transaction_with_blockchain,
          to_wallet: insert(:wallet),
          status: TransactionState.failed(),
          error_code: "some_error"
        )

      assert transaction.status == TransactionState.failed()

      {res, txn_processed} = TransactionGate.BlockchainLocal.process_with_transaction(transaction)

      assert res == :error
      assert txn_processed == transaction
    end
  end
end
