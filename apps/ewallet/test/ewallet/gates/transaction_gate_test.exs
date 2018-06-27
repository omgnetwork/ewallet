defmodule EWallet.TransactionGateTest do
  use EWallet.LocalLedgerCase, async: true
  import EWalletDB.Factory
  alias EWallet.TransactionGate
  alias EWalletDB.{User, Token, Transaction, Account}
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID

  def init_wallet(address, token, amount \\ 1_000) do
    master_account = Account.get_master_account()
    master_wallet = Account.get_primary_wallet(master_account)
    mint!(token)
    transfer!(master_wallet.address, address, token, amount * token.subunit_to_unit)
  end

  describe "process_with_addresses/1" do
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
        "idempotency_token" => idempotency_token
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
          type: Transaction.internal()
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
          "idempotency_token" => idempotency_token
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
  end
end
