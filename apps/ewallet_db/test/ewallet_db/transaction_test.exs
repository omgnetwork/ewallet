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
  alias Ecto.Changeset
  alias EWalletDB.{Transaction, Repo}
  alias Utils.Helpers.{Crypto, EIP55}

  describe "Transaction factory" do
    test_has_valid_factory(Transaction)
    test_encrypted_map_field(Transaction, "transaction", :encrypted_metadata)
    test_encrypted_map_field(Transaction, "transaction", :payload)
  end

  describe "state_changeset/4" do
    test "returns a changeset with casted fields" do
      res =
        Transaction.state_changeset(
          %Transaction{},
          %{
            "from_amount" => 1,
            "originator" => %System{}
          },
          [:from_amount],
          [:from_amount]
        )

      assert %Changeset{} = res
      assert res.errors == []
    end

    test "returns an error when a required field is missing" do
      res =
        Transaction.state_changeset(
          %Transaction{},
          %{
            "originator" => %System{}
          },
          [:from_amount],
          [:from_amount]
        )

      assert %Changeset{} = res
      assert res.errors == [from_amount: {"can't be blank", [validation: :required]}]
    end

    test "returns an error when the given status is not a valid status" do
      res =
        Transaction.state_changeset(
          %Transaction{},
          %{
            "status" => "fake",
            "originator" => %System{}
          },
          [:status],
          []
        )

      assert %Changeset{} = res
      assert res.errors == [status: {"is invalid", [validation: :inclusion]}]
    end
  end

  describe "get_last_blk_number/1" do
    test "returns the last known block number for the given blockchain identifier" do
      insert(:transaction, blockchain_identifier: "ethereum", blk_number: 230)
      insert(:transaction, blockchain_identifier: "ethereum", blk_number: 123)

      blk_number = Transaction.get_last_blk_number("ethereum")
      assert blk_number == 230
    end
  end

  describe "all_for_address/1" do
    test "returns all transactions from or to the given address" do
      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)
      wallet_3 = insert(:wallet)

      insert(:transaction, from_wallet: wallet_1, to_wallet: wallet_2)
      insert(:transaction, from_wallet: wallet_2, to_wallet: wallet_1)
      insert(:transaction, from_wallet: wallet_2, to_wallet: wallet_3)

      transactions = Transaction.all_for_address(wallet_1.address)
      assert transactions |> Repo.all() |> length() == 2
    end
  end

  describe "all_for_user/1" do
    test "returns all transactions associated that are from or to the given user" do
      user_1 = insert(:user)
      user_2 = insert(:user)
      user_3 = insert(:user)

      insert(:transaction, from_user_uuid: user_1.uuid, to_user_uuid: user_2.uuid)
      insert(:transaction, from_user_uuid: user_2.uuid, to_user_uuid: user_1.uuid)
      insert(:transaction, from_user_uuid: user_2.uuid, to_user_uuid: user_3.uuid)

      transactions = Transaction.all_for_user(user_1)
      assert transactions |> Repo.all() |> length() == 2
    end

    test "returns all transactions associated that are from or to the given user and in the given queryable" do
      user_1 = insert(:user)
      user_2 = insert(:user)
      user_3 = insert(:user)

      insert(:transaction, from_user_uuid: user_1.uuid, to_user_uuid: user_2.uuid)
      insert(:transaction, from_user_uuid: user_2.uuid, to_user_uuid: user_1.uuid)
      insert(:transaction, from_user_uuid: user_2.uuid, to_user_uuid: user_3.uuid)

      transactions = Transaction.all_for_user(user_1, Transaction)
      assert transactions |> Repo.all() |> length() == 2
    end
  end

  describe "query_all_for_account_uuids_and_users/2" do
    test "returns a query for transactions between the given accounts and any user" do
      user_1 = insert(:user)
      user_2 = insert(:user)
      user_3 = insert(:user)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      insert(:transaction, from_user_uuid: user_1.uuid, to_account_uuid: account_2.uuid)
      insert(:transaction, from_account_uuid: account_1.uuid, to_account_uuid: account_2.uuid)
      insert(:transaction, from_account_uuid: account_2.uuid, to_user_uuid: user_1.uuid)
      insert(:transaction, from_account_uuid: account_3.uuid, to_account_uuid: account_4.uuid)
      insert(:transaction, from_user_uuid: user_2.uuid, to_user_uuid: user_3.uuid)

      transactions =
        Transaction.query_all_for_account_uuids_and_users(Transaction, [
          account_1.uuid,
          account_2.uuid
        ])

      assert transactions |> Repo.all() |> length() == 4
    end
  end

  describe "query_all_for_account_uuids/2" do
    test "returns a query for transactions from or to the given accounts" do
      user_1 = insert(:user)
      user_2 = insert(:user)
      user_3 = insert(:user)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      insert(:transaction, from_user_uuid: user_1.uuid, to_account_uuid: account_2.uuid)
      insert(:transaction, from_account_uuid: account_1.uuid, to_account_uuid: account_2.uuid)
      insert(:transaction, from_account_uuid: account_2.uuid, to_user_uuid: user_1.uuid)
      insert(:transaction, from_account_uuid: account_3.uuid, to_account_uuid: account_4.uuid)
      insert(:transaction, from_user_uuid: user_2.uuid, to_user_uuid: user_3.uuid)

      transactions =
        Transaction.query_all_for_account_uuids(Transaction, [account_1.uuid, account_2.uuid])

      assert transactions |> Repo.all() |> length() == 3
    end
  end

  describe "all_for_account_and_user_uuids/2" do
    test "returns the list of transactions between the given accounts or users" do
      user_1 = insert(:user)
      user_2 = insert(:user)
      user_3 = insert(:user)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      insert(:transaction, from_user_uuid: user_1.uuid, to_account_uuid: account_2.uuid)
      insert(:transaction, from_account_uuid: account_1.uuid, to_account_uuid: account_2.uuid)
      insert(:transaction, from_account_uuid: account_2.uuid, to_user_uuid: user_1.uuid)
      insert(:transaction, from_account_uuid: account_3.uuid, to_account_uuid: account_4.uuid)
      insert(:transaction, from_user_uuid: user_2.uuid, to_user_uuid: user_3.uuid)

      transactions = Transaction.all_for_account_and_user_uuids([account_1.uuid], [user_1.uuid])
      assert transactions |> Repo.all() |> length() == 3
    end
  end

  describe "all_for_account/2" do
    test "returns the list of transactions from or to the given account" do
      user_1 = insert(:user)
      user_2 = insert(:user)
      user_3 = insert(:user)

      account_1 = insert(:account)
      account_2 = insert(:account)
      account_3 = insert(:account)
      account_4 = insert(:account)

      insert(:transaction, from_user_uuid: user_1.uuid, to_account_uuid: account_2.uuid)
      insert(:transaction, from_account_uuid: account_1.uuid, to_account_uuid: account_2.uuid)
      insert(:transaction, from_account_uuid: account_2.uuid, to_user_uuid: user_1.uuid)
      insert(:transaction, from_account_uuid: account_3.uuid, to_account_uuid: account_4.uuid)
      insert(:transaction, from_user_uuid: user_2.uuid, to_user_uuid: user_3.uuid)

      transactions = Transaction.all_for_account(account_1)
      assert transactions |> Repo.all() |> length() == 1
    end
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

    test "saves the blockchain addresses in lower case" do
      address_1 = Crypto.fake_eth_address()
      {:ok, eip55_address_1} = EIP55.encode(address_1)
      address_2 = Crypto.fake_eth_address()
      {:ok, eip55_address_2} = EIP55.encode(address_2)

      {:ok, inserted_transaction} =
        :blockchain_transaction
        |> params_for(%{
          from_blockchain_address: eip55_address_1,
          to_blockchain_address: eip55_address_2
        })
        |> Transaction.get_or_insert()

      assert inserted_transaction.from_blockchain_address == String.downcase(address_1)
      assert inserted_transaction.to_blockchain_address == String.downcase(address_2)
    end
  end

  describe "get/1" do
    test "retrieves a transaction by idempotency token" do
      {:ok, inserted_transaction} = :transaction |> params_for() |> Transaction.get_or_insert()
      transaction = Transaction.get(inserted_transaction.id)

      assert transaction.id == inserted_transaction.id
    end
  end

  describe "get_by/2" do
    test "returns a transaction by the given fields" do
      {:ok, inserted_transaction} = :transaction |> params_for() |> Transaction.get_or_insert()

      transaction =
        Transaction.get_by(%{idempotency_token: inserted_transaction.idempotency_token})

      assert transaction.id == inserted_transaction.id
    end

    test "ignore the case for `from_blockchain_address` and `to_blockchain_address`" do
      address_1 = Crypto.fake_eth_address()
      address_2 = Crypto.fake_eth_address()

      {:ok, inserted_transaction_1} =
        :blockchain_transaction
        |> params_for(%{from_blockchain_address: String.downcase(address_1)})
        |> Transaction.get_or_insert()

      {:ok, inserted_transaction_2} =
        :blockchain_transaction
        |> params_for(%{to_blockchain_address: String.downcase(address_2)})
        |> Transaction.get_or_insert()

      transaction_1 = Transaction.get_by(%{from_blockchain_address: String.upcase(address_1)})
      transaction_2 = Transaction.get_by(%{to_blockchain_address: String.upcase(address_2)})

      assert transaction_1.id == inserted_transaction_1.id
      assert transaction_2.id == inserted_transaction_2.id
    end
  end

  describe "get_by_idempotency_token/1" do
    test "returns a transaction by the given idempotency token" do
      {:ok, inserted_transaction} = :transaction |> params_for() |> Transaction.get_or_insert()
      transaction = Transaction.get_by_idempotency_token(inserted_transaction.idempotency_token)

      assert transaction.id == inserted_transaction.id
    end
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
    test "returns a tuple with code and description when transaction has error code and description" do
      transaction = insert(:transaction, error_code: "code", error_description: "description")
      assert Transaction.get_error(transaction) == {"code", "description"}
    end

    test "returns a tuple with code and data when transaction has error code and data" do
      transaction = insert(:transaction, error_code: "code", error_data: %{})
      assert Transaction.get_error(transaction) == {"code", %{}}
    end

    test "returns the error description when the transaction has both error description and data" do
      transaction =
        insert(:transaction, error_code: "code", error_description: "description", error_data: %{})

      assert Transaction.get_error(transaction) == {"code", "description"}
    end

    test "returns a tuple of nils if no error is associated with the given transaction" do
      transaction = insert(:transaction)
      assert Transaction.get_error(transaction) == {nil, nil}
    end

    test "returns nil if the given nil" do
      assert Transaction.get_error(nil) == nil
    end
  end

  describe "failed?/1" do
    test "returns true if the given transaction is failed" do
      transaction = insert(:transaction, status: "failed")
      assert Transaction.failed?(transaction) == true
    end

    test "returns true if the given transaction is not failed" do
      transaction = insert(:transaction, status: "confirmed")
      assert Transaction.failed?(transaction) == false
    end
  end
end
