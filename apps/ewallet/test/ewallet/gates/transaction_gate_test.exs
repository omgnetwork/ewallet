defmodule EWallet.TransactionGateTest do
  use EWallet.LocalLedgerCase, async: true
  import EWalletDB.Factory
  alias EWallet.TransactionGate
  alias EWalletDB.{Repo, User, Token, Transaction, Account}
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID

  def init_wallet(address, token, amount \\ 1_000) do
    master_account = Account.get_master_account()
    master_wallet = Account.get_primary_wallet(master_account)
    {:ok, account1} = Account.insert(params_for(:account))
    {:ok, account2} = Account.insert(params_for(:account))
    {:ok, token} = Token.insert(params_for(:token, subunit_to_unit: 100))
    from = Account.get_primary_wallet(account1)
    to = Account.get_primary_wallet(account2)

    mint!(token)
    transfer!(master_wallet.address, from.address, token, 1_000 * token.subunit_to_unit)

    %{
      idempotency_token: UUID.generate(),
      from: from.address,
      to: to.address,
      from_amount: 100 * token.subunit_to_unit,
      from_token_id: token.id,
      to_amount: 100 * token.subunit_to_unit,
      to_token_id: token.id,
      exchange_account_id: nil,
      metadata: %{},
      payload: %{}
    }
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

      {status, transaction, _user, _token} = TransactionGate.process_with_addresses(attrs)
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

      {status, transaction, code, description} = TransactionGate.process_with_addresses(attrs)
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

      {status, transaction, _wallets, _token} = TransactionGate.process_with_addresses(attrs)
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

      {status, transaction, code, _description} = TransactionGate.process_with_addresses(attrs)
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

      {status, _transaction, _wallets, _token} = TransactionGate.process_with_addresses(attrs)

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
        TransactionGate.process_with_addresses(%{
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

      {status, transaction, wallets, token} = TransactionGate.process_with_addresses(attrs)
      assert status == :ok
      assert transaction.idempotency_token == idempotency_token
      assert wallets == [wallet1, wallet2]
      assert token.id == token.id
    end
  end

  describe "process_credit_or_debit/1" do
    defp insert_debit_credit_records do
      {:ok, account} = Account.insert(params_for(:account))
      {:ok, user} = User.insert(params_for(:user))
      {:ok, token} = Token.insert(params_for(:token, account: account))
      {account, user, token |> Repo.preload([:account])}
    end

    defp build_debit_credit_attrs(idempotency_token, account, user, token) do
      %{
        "account_id" => account.id,
        "provider_user_id" => user.provider_user_id,
        "token_id" => token.id,
        "amount" => 100_000,
        "type" => TransactionGate.debit_type(),
        "metadata" => %{some: "data"},
        "idempotency_token" => idempotency_token
      }
    end

    def insert_debit_credit_transaction(%{
          metadata: metadata,
          response: response,
          status: status
        }) do
      idempotency_token = UUID.generate()
      {inserted_account, inserted_user, inserted_token} = insert_debit_credit_records()

      attrs =
        build_debit_credit_attrs(
          idempotency_token,
          inserted_account,
          inserted_user,
          inserted_token
        )

      {:ok, transaction} =
        Transaction.get_or_insert(%{
          idempotency_token: idempotency_token,
          from: User.get_primary_wallet(inserted_user).address,
          to: Account.get_primary_wallet(inserted_token.account).address,
          from_amount: 100_000,
          from_token_uuid: inserted_token.uuid,
          to_amount: 100_000,
          to_token_uuid: inserted_token.uuid,
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
        insert_debit_credit_transaction(%{
          metadata: %{some: "data"},
          response: %{"local_ledger_uuid" => "from cached ledger"},
          status: Transaction.confirmed()
        })

      assert inserted_transaction.status == Transaction.confirmed()

      {status, transaction, _user, _token} = TransactionGate.process_credit_or_debit(attrs)
      assert status == :ok

      assert inserted_transaction.id == transaction.id
      assert transaction.idempotency_token == idempotency_token
      assert transaction.status == Transaction.confirmed()
      assert transaction.local_ledger_uuid != nil
    end

    test "returns the transaction ledger response when idempotency token is present and
          transaction is failed" do
      {idempotency_token, inserted_transaction, attrs} =
        insert_debit_credit_transaction(%{
          metadata: %{some: "data"},
          response: %{"code" => "code!", "description" => "description!"},
          status: Transaction.failed()
        })

      assert inserted_transaction.status == Transaction.failed()

      {status, transaction, _code, _description} = TransactionGate.process_credit_or_debit(attrs)
      assert status == :error
      assert inserted_transaction.id == transaction.id
      assert transaction.idempotency_token == idempotency_token
      assert transaction.status == Transaction.failed()
      assert transaction.error_code == "code!"
      assert transaction.error_description == "description!"
    end

    test "resend the request to the ledger when idempotency token is present and
          transaction is pending" do
      {idempotency_token, inserted_transaction, attrs} =
        insert_debit_credit_transaction(%{
          metadata: %{some: "data"},
          response: nil,
          status: Transaction.pending()
        })

      assert inserted_transaction.status == Transaction.pending()
      init_wallet(inserted_transaction.from, inserted_transaction.from_token, 1_000)

      {status, transaction, _wallets, _token} = TransactionGate.process_credit_or_debit(attrs)

      assert status == :ok

      assert inserted_transaction.id == transaction.id
      assert transaction.idempotency_token == idempotency_token
      assert transaction.status == Transaction.confirmed()
    end

    test "creates and fails a transaction when idempotency token is not present and the ledger
          returned an error" do
      idempotency_token = UUID.generate()
      {inserted_account, inserted_user, inserted_token} = insert_debit_credit_records()

      attrs =
        build_debit_credit_attrs(
          idempotency_token,
          inserted_account,
          inserted_user,
          inserted_token
        )

      {status, transaction, code, _description} = TransactionGate.process_credit_or_debit(attrs)
      assert transaction.status == "failed"
      assert status == :error
      assert code == "insufficient_funds"

      transaction = Transaction.get_by(%{idempotency_token: idempotency_token})
      assert transaction.idempotency_token == idempotency_token
      assert transaction.status == Transaction.failed()

      assert transaction.payload == %{
               "provider_user_id" => inserted_user.provider_user_id,
               "token_id" => inserted_token.id,
               "amount" => 100_000,
               "type" => TransactionGate.debit_type(),
               "metadata" => %{"some" => "data"},
               "idempotency_token" => idempotency_token,
               "account_id" => inserted_account.id
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
      {inserted_account, inserted_user, inserted_token} = insert_debit_credit_records()
      wallet = User.get_primary_wallet(inserted_user)

      attrs =
        build_debit_credit_attrs(
          idempotency_token,
          inserted_account,
          inserted_user,
          inserted_token
        )

      init_wallet(wallet.address, inserted_token, 1_000)

      {status, _transaction, _wallets, _token} = TransactionGate.process_credit_or_debit(attrs)

      assert status == :ok

      transaction = Transaction.get_by(%{idempotency_token: idempotency_token})
      assert transaction.idempotency_token == idempotency_token
      assert transaction.status == Transaction.confirmed()

      assert transaction.payload == %{
               "provider_user_id" => inserted_user.provider_user_id,
               "token_id" => inserted_token.id,
               "amount" => 100_000,
               "type" => TransactionGate.debit_type(),
               "metadata" => %{"some" => "data"},
               "idempotency_token" => idempotency_token,
               "account_id" => inserted_account.id
             }

      assert transaction.local_ledger_uuid != nil
      assert transaction.metadata == %{"some" => "data"}
    end

    test "build, format and send the transaction to the local ledger" do
      idempotency_token = UUID.generate()
      {inserted_account, inserted_user, inserted_token} = insert_debit_credit_records()
      wallet = User.get_primary_wallet(inserted_user)

      attrs =
        build_debit_credit_attrs(
          idempotency_token,
          inserted_account,
          inserted_user,
          inserted_token
        )

      init_wallet(wallet.address, inserted_token, 1_000)

      {status, transaction, wallets, token} = TransactionGate.process_credit_or_debit(attrs)
      assert status == :ok
      assert transaction.idempotency_token == idempotency_token
      assert wallets == [User.get_preloaded_primary_wallet(inserted_user)]
      assert token.id == inserted_token.id
    end
  end

  describe "get_or_insert/1" do
    test "inserts a new internal transfer when not existing", attrs do
      transaction = Transaction.get(attrs.idempotency_token)
      assert transaction == nil

      {:ok, inserted_transaction} = TransactionGate.get_or_insert(attrs)

      transaction = Transaction.get_by_idempotency_token(attrs.idempotency_token)
      assert transaction.id == inserted_transaction.id
      assert transaction.type == Transaction.internal()
    end

    test "gets a transfer if already existing", attrs do
      transaction = Transaction.get(attrs.idempotency_token)
      assert transaction == nil
      assert Transaction |> Repo.all() |> length() == 2

      {:ok, inserted_transaction1} = TransactionGate.get_or_insert(attrs)
      {:ok, inserted_transaction2} = TransactionGate.get_or_insert(attrs)

      assert inserted_transaction1.id == inserted_transaction2.id
      assert Transaction |> Repo.all() |> length() == 3
    end

    test "fails to insert a transfer from a burn wallet", attrs do
      master_account = Account.get_master_account()
      burn_wallet = Account.get_default_burn_wallet(master_account)

      attrs = attrs |> Map.put(:from, burn_wallet.address)
      transaction = Transaction.get(attrs.idempotency_token)
      assert transaction == nil

      {:error, changeset} = TransactionGate.get_or_insert(attrs)

      assert changeset.errors == [
               from:
                 {"can't be the address of a burn wallet",
                  [validation: :burn_wallet_as_sender_not_allowed]}
             ]
    end

    test "fails to insert a transfer from an additional burn wallet", attrs do
      master_account = Account.get_master_account()
      burn_wallet = insert(:wallet, account: master_account, identifier: "burn_1")

      attrs = attrs |> Map.put(:from, burn_wallet.address)
      transaction = Transaction.get(attrs.idempotency_token)
      assert transaction == nil

      {:error, changeset} = TransactionGate.get_or_insert(attrs)

      assert changeset.errors == [
               from:
                 {"can't be the address of a burn wallet",
                  [validation: :burn_wallet_as_sender_not_allowed]}
             ]
    end
  end

  describe "process/1 for same token transactions" do
    test "inserts an entry and confirms the transfer when transaction succeeded", attrs do
      {:ok, transfer} = TransactionGate.get_or_insert(attrs)
      transfer = TransactionGate.process(transfer)

      assert transfer.local_ledger_uuid != nil
      assert transfer.status == Transaction.confirmed()
    end

    test "does not insert an entry and fails the transfer when transaction failed", attrs do
      attrs =
        attrs
        |> Map.put(:from_amount, 1_000_000)
        |> Map.put(:to_amount, 1_000_000)

      {:ok, transfer} = TransactionGate.get_or_insert(attrs)
      transfer = TransactionGate.process(transfer)

      assert transfer.status == Transaction.failed()
      assert transfer.error_code == "insufficient_funds"
      assert transfer.error_description == nil

      assert transfer.error_data == %{
               "address" => attrs[:from],
               "amount_to_debit" => 1_000_000,
               "current_amount" => 100_000,
               "token_id" => attrs[:from_token_id]
             }

      assert transfer.status == Transaction.failed()
    end

    test "returns the previously inserted transfer", attrs do
      assert Transaction |> Repo.all() |> length() == 2

      {:ok, transfer_1} = TransactionGate.get_or_insert(attrs)
      transfer_1 = TransactionGate.process(transfer_1)

      assert transfer_1.local_ledger_uuid != nil
      assert transfer_1.status == Transaction.confirmed()

      transfer_2 = TransactionGate.process(transfer_1)

      assert transfer_2.local_ledger_uuid != nil
      assert transfer_2.status == Transaction.confirmed()
      assert transfer_1.uuid == transfer_2.uuid
      assert Transaction |> Repo.all() |> length() == 3
    end
  end

  describe "process/1 for cross-token transactions" do
    test "inserts an entry and confirms the transfer when transaction succeeded", attrs do
      account = Account.get_master_account()
      to_token = insert(:token)
      mint!(to_token)

      {:ok, transfer} =
        attrs
        |> Map.merge(%{to_token_id: to_token.id, exchange_account_id: account.id})
        |> TransactionGate.get_or_insert()

      transfer = TransactionGate.process(transfer)

      assert transfer.local_ledger_uuid != nil
      assert transfer.status == Transaction.confirmed()
    end
  end

  describe "genesis/1" do
    test "inserts an entry and confirms the transfer when transaction succeeded", attrs do
      {:ok, transfer} = TransactionGate.get_or_insert(attrs)
      transfer = TransactionGate.genesis(transfer)

      assert transfer.status == Transaction.confirmed()
      assert transfer.local_ledger_uuid != nil
    end
  end
end
