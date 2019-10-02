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
  alias EWalletDB.{DepositTransaction, TransactionState}

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

      transaction = DepositTransaction.get_by(uuid: inserted.uuid)

      assert transaction.id == inserted.id
    end
  end

  describe "insert/1" do
    test_insert_generate_uuid(DepositTransaction, :uuid)
    test_insert_generate_external_id(DepositTransaction, :id, "dtx_")
  end

  describe "all_unfinalized_by/1" do
    test "returns all deposit transactions that are not yet finalized" do
      wallet = insert(:blockchain_deposit_wallet)

      # Transactions that are not finalized and match the address
      dtx_1 =
        insert(:deposit_transaction,
          transaction: insert(:transaction, status: TransactionState.pending_confirmations()),
          to_deposit_wallet: wallet
        )

      dtx_2 =
        insert(:deposit_transaction,
          transaction: insert(:transaction, status: TransactionState.blockchain_submitted()),
          to_deposit_wallet: wallet
        )

      # Transactions that are not finalized but have a differing address
      dtx_3 =
        insert(:deposit_transaction,
          transaction: insert(:transaction, status: TransactionState.pending_confirmations())
        )

      dtx_4 =
        insert(:deposit_transaction,
          transaction: insert(:transaction, status: TransactionState.blockchain_confirmed())
        )

      # Transactions that are excluded but does match the address
      dtx_5 =
        insert(:deposit_transaction,
          transaction: insert(:transaction, status: TransactionState.pending()),
          to_deposit_wallet: wallet
        )

      dtx_6 =
        insert(:deposit_transaction,
          transaction: insert(:transaction, status: TransactionState.blockchain_confirmed()),
          to_deposit_wallet: wallet
        )

      dtx_7 =
        insert(:deposit_transaction,
          transaction: insert(:transaction, status: TransactionState.confirmed()),
          to_deposit_wallet: wallet
        )

      dtx_8 = insert(:deposit_transaction, to_deposit_wallet: wallet)

      txns = DepositTransaction.all_unfinalized_by(to_deposit_wallet_address: wallet.address)

      assert Enum.any?(txns, fn t -> t.uuid == dtx_1.uuid end)
      assert Enum.any?(txns, fn t -> t.uuid == dtx_2.uuid end)
      refute Enum.any?(txns, fn t -> t.uuid == dtx_3.uuid end)
      refute Enum.any?(txns, fn t -> t.uuid == dtx_4.uuid end)
      refute Enum.any?(txns, fn t -> t.uuid == dtx_5.uuid end)
      refute Enum.any?(txns, fn t -> t.uuid == dtx_6.uuid end)
      refute Enum.any?(txns, fn t -> t.uuid == dtx_7.uuid end)
      refute Enum.any?(txns, fn t -> t.uuid == dtx_8.uuid end)
    end
  end
end
