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

defmodule EWalletDB.DepositTransactionTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias EWalletDB.DepositTransaction

  describe "get_highest_blk_number/1" do
    test "returns the highest block number present in the deposit transactions"
  end

  describe "get/1" do
    test "retrieves a deposit transaction by its id" do
      deposit_transaction = insert(:deposit_transaction)
      result = DepositTransaction.get(deposit_transaction.id)
      assert result.uuid == deposit_transaction.uuid
    end

    test "returns nil the deposit transaction is not found" do
      assert DepositTransaction.get("some unknown id") == nil
    end

    test "returns nil when given nil" do
      assert DepositTransaction.get(nil) == nil
    end
  end

  describe "get_by/2" do
    test "returns a deposit transaction by the given fields" do
      inserted = insert(:deposit_transaction)

      transaction =
        DepositTransaction.get_by(uuid: inserted.uuid})

      assert transaction.id == inserted.id
    end
  end

  describe "insert/1" do
    test_insert_generate_uuid(DepositTransaction, :uuid)
    test_insert_generate_external_id(DepositTransaction, :id, "dtx_")
  end

  describe "all_in_progress_by/1" do
    test "returns all deposit transactions that are in progress"
  end

  describe "get_error/1" do
    test "returns a tuple with code and description when transaction has error code and description" do
      transaction = insert(:deposit_transaction, error_code: "code", error_description: "description")
      assert DepositTransaction.get_error(transaction) == {"code", "description"}
    end

    test "returns a tuple with code and data when transaction has error code and data" do
      transaction = insert(:deposit_transaction, error_code: "code", error_data: %{})
      assert DepositTransaction.get_error(transaction) == {"code", %{}}
    end

    test "returns the error description when the transaction has both error description and data" do
      transaction =
        insert(:deposit_transaction, error_code: "code", error_description: "description", error_data: %{})

      assert DepositTransaction.get_error(transaction) == {"code", "description"}
    end

    test "returns a tuple of nils if no error is associated with the given transaction" do
      transaction = insert(:deposit_transaction)
      assert DepositTransaction.get_error(transaction) == {nil, nil}
    end

    test "returns nil if the given nil" do
      assert DepositTransaction.get_error(nil) == nil
    end
  end

  describe "failed?/1" do
    test "returns true if the given transaction is failed" do
      transaction = insert(:deposit_transaction, status: "failed")
      assert DepositTransaction.failed?(transaction) == true
    end

    test "returns true if the given transaction is not failed" do
      transaction = insert(:deposit_transaction, status: "confirmed")
      assert DepositTransaction.failed?(transaction) == false
    end
  end
end
