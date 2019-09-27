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
  alias EWallet.TransactionGate
  alias EWalletDB.TransactionState
  alias LocalLedgerDB.Factory, as: LedgerFactory

  describe "process_with_transaction/1" do
    test "returns the transaction with status:confirmed" do
      txn_inserted = insert(:blockchain_transaction, to_wallet: insert(:wallet))

      {:ok, txn_blockchain_confirmed} =
        TransactionState.transition_to(
          :from_blockchain_to_ledger,
          TransactionState.blockchain_confirmed(),
          txn_inserted,
          %{confirmations_count: 100, originator: %System{}}
        )

      assert txn_blockchain_confirmed.status == TransactionState.blockchain_confirmed()

      {res, txn_processed} =
        TransactionGate.BlockchainLocal.process_with_transaction(txn_blockchain_confirmed)

      assert res == :ok
      assert txn_processed.status == TransactionState.confirmed()
    end

    test "returns the transaction untouched if it's already in local ledger" do
      ledger_transaction = LedgerFactory.insert(:transaction)
      transaction = insert(:transaction, local_ledger_uuid: ledger_transaction.uuid)

      {:ok, txn_blockchain_confirmed} =
        TransactionState.transition_to(
          :from_blockchain_to_ledger,
          TransactionState.blockchain_confirmed(),
          transaction,
          %{confirmations_count: 100, originator: %System{}}
        )

      {res, txn_processed} =
        TransactionGate.BlockchainLocal.process_with_transaction(txn_blockchain_confirmed)

      assert res == :ok
      assert txn_processed == txn_blockchain_confirmed
    end

    test "returns the transaction untouched if an error code exists" do
      transaction = insert(:transaction, error_code: "some_error")

      {:ok, txn_blockchain_confirmed} =
        TransactionState.transition_to(
          :from_blockchain_to_ledger,
          TransactionState.blockchain_confirmed(),
          transaction,
          %{confirmations_count: 100, originator: %System{}}
        )

      {res, txn_processed} =
        TransactionGate.BlockchainLocal.process_with_transaction(txn_blockchain_confirmed)

      assert res == :ok
      assert txn_processed == txn_blockchain_confirmed
    end
  end
end
