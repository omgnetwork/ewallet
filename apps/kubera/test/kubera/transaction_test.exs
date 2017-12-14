defmodule Kubera.TransactionTest do
  use ExUnit.Case
  import KuberaDB.Factory
  import Mock
  alias Kubera.Transaction
  alias KuberaDB.{Repo, User, MintedToken, Transfer, Account}
  alias KuberaMQ.Entry
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  describe "process_with_addresses/1" do
    def insert_addresses_records do
      {:ok, user1} = User.insert(params_for(:user))
      {:ok, user2} = User.insert(params_for(:user))
      {:ok, token} = MintedToken.insert(params_for(:minted_token))

      balance1 = User.get_primary_balance(user1)
      balance2 = User.get_primary_balance(user2)

      {balance1, balance2, token}
    end

    defp build_addresses_attrs(idempotency_token, balance1, balance2, token) do
      %{
        "from_address" => balance1.address,
        "to_address" => balance2.address,
        "token_id" => token.friendly_id,
        "amount" => 100_000,
        "metadata" => %{some: "data"},
        "idempotency_token" => idempotency_token
      }
    end

    def insert_transfer_with_addresses(%{
      metadata: metadata,
      response: response,
      status: status
    }) do
      idempotency_token = UUID.generate()
      {balance1, balance2, token} = insert_addresses_records()
      attrs = build_addresses_attrs(idempotency_token, balance1, balance2, token)

      {:ok, transfer} = Transfer.get_or_insert(%{
        idempotency_token: idempotency_token,
        from: balance1.address,
        to: balance2.address,
        minted_token_id: token.id,
        amount: 100_000,
        metadata: metadata,
        payload: attrs,
        ledger_response: response,
        status: status,
        type: Transfer.internal
      })

      {idempotency_token, transfer, attrs}
    end

    test "returns the transfer ledger response when idempotency token is present and
          transfer is confirmed"
    do
      with_mock Entry,
        [insert: fn _data, _idempotency_token ->
          {:ok, %{data: "from ledger"}}
        end] do
          {idempotency_token, inserted_transfer, attrs} = insert_transfer_with_addresses(%{
            metadata: %{some: "data"},
            response: %{"data" => "from cached ledger"},
            status: Transfer.confirmed
          })

          assert inserted_transfer.status == Transfer.confirmed

          {status, transfer, _user, _minted_token} = Transaction.process_with_addresses(attrs)
          assert status == :ok

          assert inserted_transfer.id == transfer.id
          assert transfer.idempotency_token == idempotency_token
          assert transfer.status == Transfer.confirmed
          assert transfer.ledger_response == %{"data" => "from cached ledger"}
      end
    end

    test "returns the transfer ledger response when idempotency token is present and
          transfer is failed"
    do
      with_mock Entry,
        [insert: fn _data, _idempotency_token ->
          {:error, "code", "description"}
        end] do
          {idempotency_token, inserted_transfer, attrs} = insert_transfer_with_addresses(%{
            metadata: %{some: "data"},
            response: %{"code" => "code!", "description" => "description!"},
            status: Transfer.failed
          })

          assert inserted_transfer.status == Transfer.failed

          {status, code, description} = Transaction.process_with_addresses(attrs)
          assert status == :error
          assert code == "code!"
          assert description == "description!"

          transfer = Transfer.get(idempotency_token)
          assert inserted_transfer.id == transfer.id
          assert transfer.idempotency_token == idempotency_token
          assert transfer.status == Transfer.failed
          assert transfer.ledger_response == %{"code" => "code!", "description" => "description!"}
      end
    end

    test "resend the request to the ledger when idempotency token is present and
          transfer is pending"
    do
      with_mock Entry,
        [insert: fn _data, _idempotency_token ->
          {:ok, %{data: "from ledger"}}
        end] do
          {idempotency_token, inserted_transfer, attrs} = insert_transfer_with_addresses(%{
            metadata: %{some: "data"},
            response: nil,
            status: Transfer.pending
          })

          assert inserted_transfer.status == Transfer.pending

          {status, transfer, _balances, _minted_token} = Transaction.process_with_addresses(attrs)
          assert status == :ok

          assert inserted_transfer.id == transfer.id
          assert transfer.idempotency_token == idempotency_token
          assert transfer.status == Transfer.confirmed
      end
    end

    test "creates and fails a transfer when idempotency token is not present and the ledger
          returned an error"
    do
      with_mock Entry,
        [insert: fn _data, _idempotency_token ->
          {:error, "code", "description"}
        end] do
          idempotency_token = UUID.generate()
          {balance1, balance2, token} = insert_addresses_records()
          attrs = build_addresses_attrs(idempotency_token, balance1, balance2, token)

          {status, code, description} = Transaction.process_with_addresses(attrs)
          assert status == :error
          assert code == "code"
          assert description == "description"

          transfer = Transfer.get(idempotency_token)
          assert transfer.idempotency_token == idempotency_token
          assert transfer.status == Transfer.failed
          assert transfer.payload == %{
            "from_address" => balance1.address,
            "to_address" => balance2.address,
            "token_id" => token.friendly_id,
            "amount" => 100_000,
            "metadata" => %{"some" => "data"},
            "idempotency_token" => idempotency_token
          }
          assert transfer.ledger_response == %{"code" => "code", "description" => "description"}
          assert transfer.metadata == %{"some" => "data"}
      end
    end

    test "creates and confirms a transfer when idempotency token does not exist" do
      with_mock Entry,
        [insert: fn _data, _idempotency_token ->
          {:ok, %{data: "from ledger"}}
        end] do
          idempotency_token = UUID.generate()
          {balance1, balance2, token} = insert_addresses_records()
          attrs = build_addresses_attrs(idempotency_token, balance1, balance2, token)

          {status, _transfer, _balances, _minted_token} = Transaction.process_with_addresses(attrs)
          assert status == :ok

          transfer = Transfer.get(idempotency_token)
          assert transfer.idempotency_token == idempotency_token
          assert transfer.status == Transfer.confirmed
          assert transfer.payload == %{
            "from_address" => balance1.address,
            "to_address" => balance2.address,
            "token_id" => token.friendly_id,
            "amount" => 100_000,
            "metadata" => %{"some" => "data"},
            "idempotency_token" => idempotency_token
          }
          assert transfer.ledger_response == %{"data" => "from ledger"}
          assert transfer.metadata == %{"some" => "data"}
      end
    end

    test "build, format and send the transaction to the local ledger" do
      with_mock Entry,
        [insert: fn _data, _idempotency_token ->
          {:ok, %{data: "from ledger"}}
        end] do
          idempotency_token = UUID.generate()
          {balance1, balance2, token} = insert_addresses_records()
          attrs = build_addresses_attrs(idempotency_token, balance1, balance2, token)

          {status, transfer, balances, minted_token} = Transaction.process_with_addresses(attrs)
          assert status == :ok
          assert transfer.idempotency_token == idempotency_token
          assert balances == [balance1, balance2]
          assert minted_token.id == token.id
      end
    end
  end

  describe "process_credit_or_debit/1" do
    defp insert_debit_credit_records do
      {:ok, account} = Account.insert(params_for(:account))
      {:ok, user} = User.insert(params_for(:user))
      {:ok, token} = MintedToken.insert(params_for(:minted_token, account: account))
      {account, user, token |> Repo.preload([:account])}
    end

    defp build_debit_credit_attrs(idempotency_token, account, user, token) do
      %{
        "account_id" => account.id,
        "provider_user_id" => user.provider_user_id,
        "token_id" => token.friendly_id,
        "amount" => 100_000,
        "type" => Transaction.debit_type,
        "metadata" => %{some: "data"},
        "idempotency_token" => idempotency_token
      }
    end

    def insert_debit_credit_transfer(%{
      metadata: metadata,
      response: response,
      status: status
    }) do
      idempotency_token = UUID.generate()
      {inserted_account, inserted_user, inserted_token} = insert_debit_credit_records()
      attrs = build_debit_credit_attrs(idempotency_token, inserted_account,
                                       inserted_user, inserted_token)

      {:ok, transfer} = Transfer.get_or_insert(%{
        idempotency_token: idempotency_token,
        from: User.get_primary_balance(inserted_user).address,
        to: Account.get_primary_balance(inserted_token.account).address,
        minted_token_id: inserted_token.id,
        amount: 100_000,
        metadata: metadata,
        payload: attrs,
        ledger_response: response,
        status: status,
        type: Transfer.internal
      })

      {idempotency_token, transfer, attrs}
    end

    test "returns the transfer ledger response when idempotency token is present and
          transfer is confirmed"
    do
      with_mock Entry,
        [insert: fn _data, _idempotency_token ->
          {:ok, %{data: "from ledger"}}
        end] do
          {idempotency_token, inserted_transfer, attrs} = insert_debit_credit_transfer(%{
            metadata: %{some: "data"},
            response: %{"data" => "from cached ledger"},
            status: Transfer.confirmed
          })

          assert inserted_transfer.status == Transfer.confirmed

          {status, transfer, _user, _minted_token} = Transaction.process_credit_or_debit(attrs)
          assert status == :ok

          assert inserted_transfer.id == transfer.id
          assert transfer.idempotency_token == idempotency_token
          assert transfer.status == Transfer.confirmed
          assert transfer.ledger_response == %{"data" => "from cached ledger"}
      end
    end

    test "returns the transfer ledger response when idempotency token is present and
          transfer is failed"
    do
      with_mock Entry,
        [insert: fn _data, _idempotency_token ->
          {:error, "code", "description"}
        end] do
          {idempotency_token, inserted_transfer, attrs} = insert_debit_credit_transfer(%{
            metadata: %{some: "data"},
            response: %{"code" => "code!", "description" => "description!"},
            status: Transfer.failed
          })

          assert inserted_transfer.status == Transfer.failed

          {status, _user, _minted_token} = Transaction.process_credit_or_debit(attrs)
          assert status == :error

          transfer = Transfer.get(idempotency_token)
          assert inserted_transfer.id == transfer.id
          assert transfer.idempotency_token == idempotency_token
          assert transfer.status == Transfer.failed
          assert transfer.ledger_response == %{"code" => "code!", "description" => "description!"}
      end
    end

    test "resend the request to the ledger when idempotency token is present and
          transfer is pending"
    do
      with_mock Entry,
        [insert: fn _data, _idempotency_token ->
          {:ok, %{data: "from ledger"}}
        end] do
          {idempotency_token, inserted_transfer, attrs} = insert_debit_credit_transfer(%{
            metadata: %{some: "data"},
            response: nil,
            status: Transfer.pending
          })

          assert inserted_transfer.status == Transfer.pending

          {status, transfer, _balances, _minted_token} = Transaction.process_credit_or_debit(attrs)
          assert status == :ok

          assert inserted_transfer.id == transfer.id
          assert transfer.idempotency_token == idempotency_token
          assert transfer.status == Transfer.confirmed
      end
    end

    test "creates and fails a transfer when idempotency token is not present and the ledger
          returned an error"
    do
      with_mock Entry,
        [insert: fn _data, _idempotency_token ->
          {:error, "code", "description"}
        end] do
          idempotency_token = UUID.generate()
          {inserted_account, inserted_user, inserted_token} = insert_debit_credit_records()
          attrs = build_debit_credit_attrs(idempotency_token, inserted_account,
                                           inserted_user, inserted_token)

          {status, code, description} = Transaction.process_credit_or_debit(attrs)
          assert status == :error
          assert code == "code"
          assert description == "description"

          transfer = Transfer.get(idempotency_token)
          assert transfer.idempotency_token == idempotency_token
          assert transfer.status == Transfer.failed
          assert transfer.payload == %{
            "provider_user_id" => inserted_user.provider_user_id,
            "token_id" => inserted_token.friendly_id,
            "amount" => 100_000,
            "type" => Transaction.debit_type,
            "metadata" => %{"some" => "data"},
            "idempotency_token" => idempotency_token,
            "account_id" => inserted_account.id
          }
          assert transfer.ledger_response == %{"code" => "code", "description" => "description"}
          assert transfer.metadata == %{"some" => "data"}
      end
    end

    test "creates and confirms a transfer when idempotency token does not exist" do
      with_mock Entry,
        [insert: fn _data, _idempotency_token ->
          {:ok, %{data: "from ledger"}}
        end] do
          idempotency_token = UUID.generate()
          {inserted_account, inserted_user, inserted_token} = insert_debit_credit_records()
          attrs = build_debit_credit_attrs(idempotency_token, inserted_account,
                                           inserted_user, inserted_token)

          {status, _transfer, _balances, _minted_token} = Transaction.process_credit_or_debit(attrs)
          assert status == :ok

          transfer = Transfer.get(idempotency_token)
          assert transfer.idempotency_token == idempotency_token
          assert transfer.status == Transfer.confirmed
          assert transfer.payload == %{
            "provider_user_id" => inserted_user.provider_user_id,
            "token_id" => inserted_token.friendly_id,
            "amount" => 100_000,
            "type" => Transaction.debit_type,
            "metadata" => %{"some" => "data"},
            "idempotency_token" => idempotency_token,
            "account_id" => inserted_account.id
          }
          assert transfer.ledger_response == %{"data" => "from ledger"}
          assert transfer.metadata == %{"some" => "data"}
      end
    end

    test "build, format and send the transaction to the local ledger" do
      with_mock Entry,
        [insert: fn _data, _idempotency_token ->
          {:ok, %{data: "from ledger"}}
        end] do
          idempotency_token = UUID.generate()
          {inserted_account, inserted_user, inserted_token} = insert_debit_credit_records()
          attrs = build_debit_credit_attrs(idempotency_token, inserted_account,
                                           inserted_user, inserted_token)

          {status, transfer, balances, minted_token} = Transaction.process_credit_or_debit(attrs)
          assert status == :ok
          assert transfer.idempotency_token == idempotency_token
          assert balances == [User.get_preloaded_primary_balance(inserted_user)]
          assert minted_token.id == inserted_token.id
      end
    end
  end
end
