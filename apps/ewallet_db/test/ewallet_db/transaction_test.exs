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

defmodule EWalletDB.TransactionTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias ActivityLogger.System
  alias Ecto.UUID
  alias EWalletDB.{Transaction, TransactionState, Repo}

  describe "Transaction factory" do
    test_has_valid_factory(Transaction)
    test_encrypted_map_field(Transaction, "transaction", :encrypted_metadata)
    test_encrypted_map_field(Transaction, "transaction", :payload)
  end

  describe "state_changeset/4" do
    test "returns a changeset with casted fields"
    test "returns an error when a required field is missing"
    test "returns an error when the given status is not a valid status"
  end

  describe "get_last_blk_number/1" do
    test "returns the last known block number for the given blockchain identifier"
  end

  describe "all_for_address/1" do
    test "returns all transactions from or to the given address"
  end

  describe "all_for_user/1" do
    test "returns all transactions associated that are from or to the given user"
    test "returns all transactions associated that are from or to the given user and in the given queryable"
  end

  describe "query_all_for_account_uuids_and_users/2" do
    test "returns a query for transactions between the given accounts and any user"
  end

  describe "query_all_for_account_uuids/2" do
    test "returns a query for transactions from or to the given accounts"
  end

  describe "all_for_account_and_user_uuids/2" do
    test "returns the list of transactions between the given accounts or users"
  end

  describe "all_for_account/2" do
    test "returns the list of transactions from or to the given account"
  end

  describe "get_or_insert/1" do
    test "inserts a new transaction when idempotency token does not exist" do
      {:ok, transaction} = :transaction |> params_for() |> Transaction.get_or_insert()

      assert transaction.id != nil
      assert transaction.type == Transaction.internal()
    end

    test "retrieves an existing transaction when idempotency token exists" do
      params = :transaction |> params_for()
      {:ok, inserted_transaction} = params |> Transaction.get_or_insert()
      {:ok, transaction} = params |> Transaction.get_or_insert()

      assert transaction.id == inserted_transaction.id
    end
  end

  describe "get/1" do
    test "retrieves a transaction by idempotency token" do
      {:ok, inserted_transaction} = :transaction |> params_for() |> Transaction.get_or_insert()
      transaction = Transaction.get_by_idempotency_token(inserted_transaction.idempotency_token)

      assert transaction.id == inserted_transaction.id
    end
  end

  describe "get_by/2" do
    test "returns a transaction by the given fields"
  end

  describe "get_by_idempotency_token/1" do
    test "returns a transaction by the given idempotency token"
  end

  describe "insert/1" do
    test_insert_generate_uuid(Transaction, :uuid)
    test_insert_generate_external_id(Transaction, :id, "txn_")
    test_insert_generate_timestamps(Transaction)
    test_insert_prevent_blank(Transaction, :payload)
    test_insert_prevent_blank(Transaction, :idempotency_token)
    test_default_metadata_fields(Transaction, "transaction")

    test "inserts a transaction if it does not existing" do
      assert Repo.all(Transaction) == []

      {:ok, transaction} =
        :transaction
        |> params_for()
        |> Transaction.insert()

      transactions =
        Transaction
        |> Repo.all()
        |> Repo.preload([:from_wallet, :to_wallet, :from_token, :to_token])

      assert transactions == [transaction]
    end

    test "returns the existing transaction without error if already existing" do
      assert Repo.all(Transaction) == []

      {:ok, inserted_transaction} =
        :transaction |> params_for(idempotency_token: "123") |> Transaction.insert()

      {:ok, transaction} =
        :transaction |> params_for(idempotency_token: "123") |> Transaction.insert()

      assert inserted_transaction == transaction
      assert Transaction |> Repo.all() |> length() == 1
    end

    test "returns an error when passing invalid arguments" do
      assert Repo.all(Transaction) == []

      {res, changeset} =
        %{idempotency_token: nil, payload: %{}, originator: %System{}} |> Transaction.insert()

      assert res == :error

      assert changeset.errors == [
               {%{to: "gnis000000000000", to_account_uuid: nil, to_user_uuid: nil},
                {"can't all be blank", [validation: :required_exclusive]}},
               {%{from: "gnis000000000000", from_account_uuid: nil, from_user_uuid: nil},
                {"can't all be blank", [validation: :required_exclusive]}},
               {:idempotency_token, {"can't be blank", [validation: :required]}},
               {:from_amount, {"can't be blank", [validation: :required]}},
               {:from_token_uuid, {"can't be blank", [validation: :required]}},
               {:to_amount, {"can't be blank", [validation: :required]}},
               {:to_token_uuid, {"can't be blank", [validation: :required]}},
               {:to, {"can't be blank", [validation: :required]}},
               {:from, {"can't be blank", [validation: :required]}}
             ]
    end

    test "succeed with from_amount < 100_000_000_000_000_000_000_000_000_000_000_000" do
      {res, transaction} =
        :transaction
        |> params_for(from_amount: 99_999_999_999_999_999_999_999_999_999_999_999)
        |> Transaction.insert()

      assert res == :ok
      assert transaction.from_amount == 99_999_999_999_999_999_999_999_999_999_999_999
    end

    test "succeed with to_amount < 100_000_000_000_000_000_000_000_000_000_000_000" do
      {res, transaction} =
        :transaction
        |> params_for(to_amount: 99_999_999_999_999_999_999_999_999_999_999_999)
        |> Transaction.insert()

      assert res == :ok
      assert transaction.to_amount == 99_999_999_999_999_999_999_999_999_999_999_999
    end
  end

  describe "confirm/2" do
    test "confirms a transaction" do
      {:ok, inserted_transaction} = :transaction |> params_for() |> Transaction.get_or_insert()
      assert inserted_transaction.status == TransactionState.pending()
      local_ledger_uuid = UUID.generate()
      transaction = Transaction.confirm(inserted_transaction, local_ledger_uuid, %System{})
      assert transaction.id == inserted_transaction.id
      assert transaction.status == Transaction.confirmed()
      assert transaction.local_ledger_uuid == local_ledger_uuid
    end
  end

  describe "fail/2" do
    test "sets a transaction as failed" do
      {:ok, inserted_transaction} = :transaction |> params_for() |> Transaction.get_or_insert()
      assert inserted_transaction.status == TransactionState.pending()
      transaction = Transaction.fail(inserted_transaction, "error", "desc", %System{})
      assert transaction.id == inserted_transaction.id
      assert transaction.status == Transaction.failed()
      assert transaction.error_code == "error"
      assert transaction.error_description == "desc"
      assert transaction.error_data == nil
    end

    test "sets a transaction as failed with atom error" do
      {:ok, inserted_transaction} = :transaction |> params_for() |> Transaction.get_or_insert()
      assert inserted_transaction.status == TransactionState.pending()
      transaction = Transaction.fail(inserted_transaction, :error, "desc", %System{})
      assert transaction.id == inserted_transaction.id
      assert transaction.status == Transaction.failed()
      assert transaction.error_code == "error"
      assert transaction.error_description == "desc"
      assert transaction.error_data == nil
    end

    test "sets a transaction as failed with error_data" do
      {:ok, inserted_transaction} = :transaction |> params_for() |> Transaction.get_or_insert()
      assert inserted_transaction.status == TransactionState.pending()
      transaction = Transaction.fail(inserted_transaction, "error", %{}, %System{})
      assert transaction.id == inserted_transaction.id
      assert transaction.status == Transaction.failed()
      assert transaction.error_code == "error"
      assert transaction.error_description == nil
      assert transaction.error_data == %{}
    end

    test "fails when from_amount is >= 100_000_000_000_000_000_000_000_000_000_000_000 (max 35 digits)" do
      {res, error} =
        :transaction
        |> params_for(from_amount: 100_000_000_000_000_000_000_000_000_000_000_000)
        |> Transaction.insert()

      assert res == :error

      assert error.errors == [
               from_amount:
                 {"must be less than %{number}",
                  [
                    validation: :number,
                    kind: :less_than,
                    number: 100_000_000_000_000_000_000_000_000_000_000_000
                  ]}
             ]
    end

    test "fails when to_amount is >= 100_000_000_000_000_000_000_000_000_000_000_000 (max 35 digits)" do
      {res, error} =
        :transaction
        |> params_for(to_amount: 100_000_000_000_000_000_000_000_000_000_000_000)
        |> Transaction.insert()

      assert res == :error

      assert error.errors == [
               to_amount:
                 {"must be less than %{number}",
                  [
                    validation: :number,
                    kind: :less_than,
                    number: 100_000_000_000_000_000_000_000_000_000_000_000
                  ]}
             ]
    end
  end

  describe "get_error/1" do
    test "returns a tuple with code and description when transaction has error code and description"
    test "returns a tuple with code and data when transaction has error code and data"
    test "returns the error description when the transaction has both error description and data"
    test "returns a tuple of nils if no error is associated with the given transaction"
    test "returns nil if the given nil"
  end

  describe "failed?/1" do
    test "returns true if the given transaction is failed"
    test "returns true if the given transaction is not failed"
  end
end
