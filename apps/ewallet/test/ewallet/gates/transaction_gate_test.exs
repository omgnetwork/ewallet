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

defmodule EWallet.TransactionGateTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias Ecto.UUID
  alias EWallet.{BalanceFetcher, TransactionGate}
  alias EWalletDB.{Account, Token, Transaction, User, Wallet}
  alias ActivityLogger.System

  def init_wallet(address, token, amount \\ 1_000) do
    master_account = Account.get_master_account()
    master_wallet = Account.get_primary_wallet(master_account)
    mint!(token)
    transfer!(master_wallet.address, address, token, amount * token.subunit_to_unit)
  end

  describe "create/1" do
    def insert_addresses_records do
      {:ok, user1} = User.insert(params_for(:user))
      {:ok, user2} = User.insert(params_for(:user))
      {:ok, token} = Token.insert(params_for(:token))

      wallet1 = User.get_primary_wallet(user1)
      wallet2 = User.get_primary_wallet(user2)

      {wallet1, wallet2, token}
    end

    defp build_addresses_attrs(idempotency_token, wallet1, wallet2, token) do
      %{
        "from_address" => wallet1.address,
        "to_address" => wallet2.address,
        "token_id" => token.id,
        "amount" => 100 * token.subunit_to_unit,
        "metadata" => %{some: "data"},
        "idempotency_token" => idempotency_token,
        "originator" => %System{}
      }
    end

    def insert_transaction_with_addresses(%{
          metadata: metadata,
          response: response,
          status: status
        }) do
      idempotency_token = UUID.generate()
      {wallet1, wallet2, token} = insert_addresses_records()
      attrs = build_addresses_attrs(idempotency_token, wallet1, wallet2, token)

      {:ok, transaction} =
        Transaction.get_or_insert(%{
          idempotency_token: idempotency_token,
          from_user_uuid: wallet1.user_uuid,
          to_user_uuid: wallet2.user_uuid,
          from: wallet1.address,
          to: wallet2.address,
          from_amount: 100 * token.subunit_to_unit,
          from_token_uuid: token.uuid,
          to_amount: 100 * token.subunit_to_unit,
          to_token_uuid: token.uuid,
          metadata: metadata,
          payload: attrs,
          local_ledger_uuid: response["local_ledger_uuid"],
          error_code: response["code"],
          error_description: response["description"],
          error_data: nil,
          status: status,
          type: Transaction.internal(),
          originator: %System{}
        })

      {idempotency_token, transaction, attrs}
    end

    test "returns the transaction ledger response when idempotency token is present and
          transaction is confirmed" do
      {idempotency_token, inserted_transaction, attrs} =
        insert_transaction_with_addresses(%{
          metadata: %{some: "data"},
          response: %{"local_ledger_uuid" => "from cached ledger"},
          status: Transaction.confirmed()
        })

      assert inserted_transaction.status == Transaction.confirmed()

      {status, transaction} = TransactionGate.create(attrs)
      assert status == :ok

      assert inserted_transaction.id == transaction.id
      assert transaction.idempotency_token == idempotency_token
      assert transaction.status == Transaction.confirmed()
      assert transaction.local_ledger_uuid == "from cached ledger"
    end

    test "returns the transaction ledger response when idempotency token is present and
          transaction is failed" do
      {idempotency_token, inserted_transaction, attrs} =
        insert_transaction_with_addresses(%{
          metadata: %{some: "data"},
          response: %{"code" => "code!", "description" => "description!"},
          status: Transaction.failed()
        })

      assert inserted_transaction.status == Transaction.failed()

      {status, transaction, code, description} = TransactionGate.create(attrs)
      assert status == :error
      assert code == "code!"
      assert description == "description!"
      assert inserted_transaction.id == transaction.id
      assert transaction.idempotency_token == idempotency_token
      assert transaction.status == Transaction.failed()
      assert transaction.error_code == "code!"
      assert transaction.error_description == "description!"
    end

    test "resend the request to the ledger when idempotency token is present and
          transaction is pending" do
      {idempotency_token, inserted_transaction, attrs} =
        insert_transaction_with_addresses(%{
          metadata: %{some: "data"},
          response: nil,
          status: Transaction.pending()
        })

      assert inserted_transaction.status == Transaction.pending()
      init_wallet(inserted_transaction.from, inserted_transaction.from_token, 1_000)

      {status, transaction} = TransactionGate.create(attrs)
      assert status == :ok

      assert inserted_transaction.id == transaction.id
      assert transaction.idempotency_token == idempotency_token
      assert transaction.status == Transaction.confirmed()
    end

    test "creates and fails a transaction when idempotency token is not present and the ledger
          returned an error" do
      idempotency_token = UUID.generate()
      {wallet1, wallet2, token} = insert_addresses_records()
      attrs = build_addresses_attrs(idempotency_token, wallet1, wallet2, token)

      {status, transaction, code, _description} = TransactionGate.create(attrs)
      assert status == :error
      assert transaction.status == Transaction.failed()
      assert code == "insufficient_funds"

      transaction = Transaction.get_by(%{idempotency_token: idempotency_token})
      assert transaction.idempotency_token == idempotency_token
      assert transaction.status == Transaction.failed()

      assert transaction.payload == %{
               "from_address" => wallet1.address,
               "to_address" => wallet2.address,
               "token_id" => token.id,
               "amount" => 100 * token.subunit_to_unit,
               "metadata" => %{"some" => "data"},
               "idempotency_token" => idempotency_token
             }

      assert transaction.error_code == "insufficient_funds"

      assert %{
               "address" => _,
               "current_amount" => _,
               "amount_to_debit" => _,
               "token_id" => _
             } = transaction.error_data

      assert transaction.metadata == %{"some" => "data"}
    end

    test "creates and confirms a transaction when idempotency token does not exist" do
      idempotency_token = UUID.generate()
      {wallet1, wallet2, token} = insert_addresses_records()
      attrs = build_addresses_attrs(idempotency_token, wallet1, wallet2, token)
      init_wallet(wallet1.address, token, 1_000)

      {status, _transaction} = TransactionGate.create(attrs)

      assert status == :ok

      transaction = Transaction.get_by(%{idempotency_token: idempotency_token})
      assert transaction.idempotency_token == idempotency_token
      assert transaction.status == Transaction.confirmed()

      assert transaction.payload == %{
               "from_address" => wallet1.address,
               "to_address" => wallet2.address,
               "token_id" => token.id,
               "amount" => 100 * token.subunit_to_unit,
               "metadata" => %{"some" => "data"},
               "idempotency_token" => idempotency_token
             }

      assert transaction.local_ledger_uuid != nil
      assert transaction.metadata == %{"some" => "data"}
    end

    test "gets back an 'amount_is_zero' error when amount sent is 0" do
      idempotency_token = UUID.generate()
      {wallet1, wallet2, token} = insert_addresses_records()

      {res, transaction, code, _description} =
        TransactionGate.create(%{
          "from_address" => wallet1.address,
          "to_address" => wallet2.address,
          "token_id" => token.id,
          "amount" => 0,
          "metadata" => %{some: "data"},
          "idempotency_token" => idempotency_token,
          "originator" => %System{}
        })

      assert res == :error
      assert transaction.status == Transaction.failed()
      assert code == "amount_is_zero"
    end

    test "build, format and send the transaction to the local ledger" do
      idempotency_token = UUID.generate()
      {wallet1, wallet2, token} = insert_addresses_records()
      attrs = build_addresses_attrs(idempotency_token, wallet1, wallet2, token)
      init_wallet(wallet1.address, token, 1_000)

      {status, transaction} = TransactionGate.create(attrs)
      assert status == :ok
      assert transaction.idempotency_token == idempotency_token
      assert transaction.from == wallet1.address
      assert transaction.to == wallet2.address
      assert token.id == token.id
    end

    test "fails to create the transaction when the token is disabled" do
      idempotency_token = UUID.generate()
      {wallet1, wallet2, token} = insert_addresses_records()

      attrs = build_addresses_attrs(idempotency_token, wallet1, wallet2, token)
      init_wallet(wallet1.address, token, 1_000)

      {:ok, _token} =
        Token.enable_or_disable(token, %{
          enabled: false,
          originator: %System{}
        })

      {status, code} = TransactionGate.create(attrs)
      assert status == :error
      assert code == :token_is_disabled
    end

    test "fails to create the transaction when the from_wallet is disabled" do
      idempotency_token = UUID.generate()
      {_wallet1, wallet2, token} = insert_addresses_records()
      account = Account.get_master_account()

      {:ok, wallet3} =
        Wallet.insert_secondary_or_burn(%{
          "account_uuid" => account.uuid,
          "name" => "MySecondary",
          "identifier" => "secondary",
          "originator" => %System{}
        })

      attrs = build_addresses_attrs(idempotency_token, wallet3, wallet2, token)
      init_wallet(wallet3.address, token, 1_000)

      {:ok, _wallet3} =
        Wallet.enable_or_disable(wallet3, %{
          enabled: false,
          originator: %System{}
        })

      {status, code} = TransactionGate.create(attrs)
      assert status == :error
      assert code == :from_wallet_is_disabled
    end

    test "fails to create the transaction when the to_wallet is disabled" do
      idempotency_token = UUID.generate()
      {wallet1, _wallet2, token} = insert_addresses_records()
      account = Account.get_master_account()

      {:ok, wallet3} =
        Wallet.insert_secondary_or_burn(%{
          "account_uuid" => account.uuid,
          "name" => "MySecondary",
          "identifier" => "secondary",
          "originator" => %System{}
        })

      attrs = build_addresses_attrs(idempotency_token, wallet1, wallet3, token)
      init_wallet(wallet1.address, token, 1_000)

      {:ok, _wallet3} =
        Wallet.enable_or_disable(wallet3, %{
          enabled: false,
          originator: %System{}
        })

      {status, code} = TransactionGate.create(attrs)
      assert status == :error
      assert code == :to_wallet_is_disabled
    end
  end

  describe "create/1 with exchange" do
    test "exchanges funds between two users" do
      account = Account.get_master_account()
      wallet = Account.get_primary_wallet(account)
      {:ok, user_1} = :user |> params_for() |> User.insert()
      {:ok, user_2} = :user |> params_for() |> User.insert()
      wallet_1 = User.get_primary_wallet(user_1)
      wallet_2 = User.get_primary_wallet(user_2)

      token_1 = insert(:token)
      token_2 = insert(:token)
      pair = insert(:exchange_pair, from_token: token_1, to_token: token_2, rate: 2)

      mint!(token_1)
      mint!(token_2)

      initialize_wallet(wallet_1, 200_000, token_1)

      {:ok, transaction} =
        TransactionGate.create(%{
          "idempotency_token" => UUID.generate(),
          "from_user_id" => user_1.id,
          "to_user_id" => user_2.id,
          "from_token_id" => token_1.id,
          "to_token_id" => token_2.id,
          "from_amount" => 100 * token_1.subunit_to_unit,
          "to_amount" => 200 * token_1.subunit_to_unit,
          "exchange_account_id" => account.id,
          "metadata" => %{something: "interesting"},
          "encrypted_metadata" => %{something: "secret"},
          "originator" => %System{}
        })

      {:ok, b1} = BalanceFetcher.get(token_1.id, wallet_1)
      assert List.first(b1.balances).amount == (200_000 - 100) * token_1.subunit_to_unit
      {:ok, b2} = BalanceFetcher.get(token_2.id, wallet_2)
      assert List.first(b2.balances).amount == 200 * token_2.subunit_to_unit

      assert transaction.from == wallet_1.address
      assert transaction.to == wallet_2.address

      assert transaction.from_user_uuid == user_1.uuid
      assert transaction.to_user_uuid == user_2.uuid

      assert transaction.from_account_uuid == nil
      assert transaction.to_account_uuid == nil

      assert transaction.from_token_uuid == token_1.uuid
      assert transaction.to_token_uuid == token_2.uuid

      assert transaction.from_amount == 100 * token_1.subunit_to_unit
      assert transaction.to_amount == 200 * token_2.subunit_to_unit

      assert transaction.rate == 2
      assert transaction.exchange_pair_uuid == pair.uuid
      assert transaction.exchange_account_uuid == account.uuid
      assert transaction.exchange_wallet_address == wallet.address
    end
  end
end
