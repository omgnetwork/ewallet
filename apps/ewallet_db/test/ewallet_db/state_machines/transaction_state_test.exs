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

defmodule EWalletDB.TransactionStateTest do
  use EWalletDB.SchemaCase, async: true

  describe "transition_to/4 for local-to-local transactions" do
    test "update and return the transaction successfully"
    test "transition from pending to confirmed successfully"
    test "transition from pending to failed successfully"
    test "returns error when transitioning from confirmed to other statuses"
    test "returns error when transitioning from failed to other statuses"

    # test "confirms a transaction" do
    #   {:ok, inserted_transaction} = :transaction |> params_for() |> Transaction.get_or_insert()
    #   assert inserted_transaction.status == TransactionState.pending()
    #   local_ledger_uuid = UUID.generate()
    #   transaction = Transaction.confirm(inserted_transaction, local_ledger_uuid, %System{})
    #   assert transaction.id == inserted_transaction.id
    #   assert transaction.status == TransactionState.confirmed()
    #   assert transaction.local_ledger_uuid == local_ledger_uuid
    # end

    # test "sets a transaction as failed" do
    #   {:ok, inserted_transaction} = :transaction |> params_for() |> Transaction.get_or_insert()
    #   assert inserted_transaction.status == TransactionState.pending()
    #   transaction = Transaction.fail(inserted_transaction, "error", "desc", %System{})
    #   assert transaction.id == inserted_transaction.id
    #   assert transaction.status == TransactionState.failed()
    #   assert transaction.error_code == "error"
    #   assert transaction.error_description == "desc"
    #   assert transaction.error_data == nil
    # end

    # test "sets a transaction as failed with atom error" do
    #   {:ok, inserted_transaction} = :transaction |> params_for() |> Transaction.get_or_insert()
    #   assert inserted_transaction.status == TransactionState.pending()
    #   transaction = Transaction.fail(inserted_transaction, :error, "desc", %System{})
    #   assert transaction.id == inserted_transaction.id
    #   assert transaction.status == TransactionState.failed()
    #   assert transaction.error_code == "error"
    #   assert transaction.error_description == "desc"
    #   assert transaction.error_data == nil
    # end

    # test "sets a transaction as failed with error_data" do
    #   {:ok, inserted_transaction} = :transaction |> params_for() |> Transaction.get_or_insert()
    #   assert inserted_transaction.status == TransactionState.pending()
    #   transaction = Transaction.fail(inserted_transaction, "error", %{}, %System{})
    #   assert transaction.id == inserted_transaction.id
    #   assert transaction.status == TransactionState.failed()
    #   assert transaction.error_code == "error"
    #   assert transaction.error_description == nil
    #   assert transaction.error_data == %{}
    # end
  end

  describe "transition_to/4 for blockchain-to-ewallet transactions" do
    test "update and return the transaction successfully"
    test "transition from pending to pending_confirmations successfully"
    test "transition from pending to blockchain_confirmed successfully"
    test "transition from pending_confirmations to blockchain_confirmed successfully"
    test "transition from blockchain_confirmed to confirmed successfully"
    test "returns error when transitioning from confirmed to other statuses"
  end

  describe "transition_to/4 for ewallet-to-blockchain transactions" do
    test "update and return the transaction successfully"
    test "transition from pending to blockchain_submitted successfully"
    test "transition from blockchain_submitted to pending_confirmations successfully"
    test "transition from pending_confirmations to blockchain_confirmed successfully"
    test "transition from blockchain_confirmed to confirmed successfully"
    test "returns error when transitioning from confirmed to other statuses"
  end

  describe "transition_to/4 for blockchain-to-local transactions" do
    test "update and return the transaction successfully"
    test "transition from pending to pending_confirmations successfully"
    test "transition from pending to blockchain_confirmed successfully"
    test "transition from pending_confirmations to blockchain_confirmed successfully"
    test "transition from blockchain_confirmed to confirmed successfully"
    test "transition from blockchain_confirmed to failed successfully"
    test "returns error when transitioning from confirmed to other statuses"
    test "returns error when transitioning from failed to other statuses"
  end

  describe "transition_to/4 for local-to-blockchain transactions" do
    test "update and return the transaction successfully"
    test "transition from pending to ledger_pending successfully"
    test "transition from pending to failed successfully"
    test "transition from ledger_pending to blockchain_submitted successfully"
    test "transition from blockchain_submitted to pending_confirmations successfully"
    test "transition from pending_confirmations to blockchain_confirmed successfully"
    test "transition from blockchain_confirmed to confirmed successfully"
    test "returns error when transitioning from confirmed to other statuses"
  end
end
