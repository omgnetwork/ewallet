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

defmodule EWallet.GenesisGateTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias Ecto.UUID
  alias EWallet.GenesisGate
  alias EWalletDB.{Account, Transaction}
  alias LocalLedgerDB.Transaction, as: LedgerTransaction

  setup do
    {:ok, account} = :account |> params_for() |> Account.insert()

    attrs = %{
      idempotency_token: UUID.generate(),
      account: account,
      token: insert(:token),
      amount: 1_000_000,
      attrs: %{
        "metadata" => %{"foo" => "bar"},
        "encrypted_metadata" => nil
      },
      originator: insert(:user)
    }

    %{
      attrs: attrs
    }
  end

  describe "create/1" do
    test "returns a genesis transaction", context do
      {res, transaction} = GenesisGate.create(context.attrs)

      assert res == :ok
      assert %Transaction{} = transaction
      assert transaction.idempotency_token == context.attrs.idempotency_token
    end

    test "defaults the metadata to an empty map", context do
      {res, transaction} =
        context.attrs
        |> Map.put(:attrs, %{"metadata" => nil})
        |> GenesisGate.create()

      assert res == :ok
      assert transaction.metadata == %{}
    end

    test "defaults the encrypted_metadata to an empty map", context do
      {res, transaction} =
        context.attrs
        |> Map.put(:attrs, %{"encrypted_metadata" => nil})
        |> GenesisGate.create()

      assert res == :ok
      assert transaction.encrypted_metadata == %{}
    end

    test "does not save the orignator to the payload", context do
      {res, transaction} =
        context.attrs
        |> Map.put(:attrs, %{"foo" => "bar"})
        |> GenesisGate.create()

      assert res == :ok
      assert transaction.payload["foo"] == "bar"
      refute Map.has_key?(transaction.payload, "originator")
    end
  end

  describe "process_with_transaction/2 with a pending transaction" do
    test "returns the mint and the confirmed transaction", context do
      {:ok, transaction} = GenesisGate.create(context.attrs)

      mint =
        insert(:mint, token_uuid: context.attrs.token.uuid, transaction_uuid: transaction.uuid)

      assert transaction.status == Transaction.pending()
      refute mint.confirmed

      {res, processed_mint, processed_transaction} =
        GenesisGate.process_with_transaction(transaction, mint)

      assert res == :ok
      assert processed_mint.uuid == mint.uuid
      assert processed_mint.confirmed
      assert processed_transaction.uuid == processed_transaction.uuid
      assert processed_transaction.status == Transaction.confirmed()
    end

    test "inserts a corresponding local ledger transaction", context do
      {:ok, transaction} = GenesisGate.create(context.attrs)

      mint =
        insert(:mint, token_uuid: context.attrs.token.uuid, transaction_uuid: transaction.uuid)

      assert transaction.status == Transaction.pending()
      refute mint.confirmed

      {res, _, _} = GenesisGate.process_with_transaction(transaction, mint)
      ledger_txn = LedgerTransaction.get_by_idempotency_token(context.attrs.idempotency_token)

      assert res == :ok
      assert %LedgerTransaction{} = ledger_txn
      assert ledger_txn.idempotency_token == context.attrs.idempotency_token
    end
  end

  describe "process_with_transaction/2 with a confirmed transaction" do
    test "returns the mint and the confirmed transaction", context do
      {:ok, transaction} = GenesisGate.create(context.attrs)

      mint =
        insert(:mint, token_uuid: context.attrs.token.uuid, transaction_uuid: transaction.uuid)

      {:ok, mint, transaction} = GenesisGate.process_with_transaction(transaction, mint)

      assert transaction.status == Transaction.confirmed()
      assert mint.confirmed

      {res, processed_mint, processed_transaction} =
        GenesisGate.process_with_transaction(transaction, mint)

      assert res == :ok
      assert processed_mint.uuid == mint.uuid
      assert processed_mint.confirmed
      assert processed_transaction.uuid == processed_transaction.uuid
      assert processed_transaction.status == Transaction.confirmed()
    end
  end

  describe "process_with_transaction/2 with a failed transaction" do
    test "returns the mint and the confirmed transaction", context do
      {:ok, transaction} = GenesisGate.create(context.attrs)

      mint =
        insert(:mint, token_uuid: context.attrs.token.uuid, transaction_uuid: transaction.uuid)

      transaction =
        Map.merge(transaction, %{
          status: Transaction.failed(),
          error_code: :some_error_code,
          error_description: "some error description"
        })

      assert transaction.status == Transaction.failed()
      refute mint.confirmed

      {res, code, description, returned_mint} =
        GenesisGate.process_with_transaction(transaction, mint)

      assert res == :error
      assert code == :some_error_code
      assert description == "some error description"
      assert returned_mint.uuid == mint.uuid
      refute returned_mint.confirmed
    end
  end
end
