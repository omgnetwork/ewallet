defmodule Kubera.TransactionTest do
  use ExUnit.Case
  import KuberaDB.Factory
  import Mock
  alias Kubera.Transaction
  alias KuberaDB.{Repo, User, MintedToken, Transfer}
  alias KuberaMQ.Entry
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  describe "process/2" do
    defp insert_user_and_token do
      {:ok, inserted_user} = User.insert(params_for(:user))
      {:ok, inserted_token} = MintedToken.insert(params_for(:minted_token))
      {inserted_user, inserted_token}
    end

    defp build_attrs(idempotency_token, user, token) do
      %{
        "provider_user_id" => user.provider_user_id,
        "token_id" => token.friendly_id,
        "amount" => 100_000,
        "type" => Transaction.debit_type,
        "metadata" => %{some: "data"},
        "idempotency_token" => idempotency_token
      }
    end

    test "returns the transfer ledger response when idempotency token is present and
          transfer is confirmed"
    do
      with_mock Entry,
        [insert: fn _data, _idempotency_token ->
          {:ok, %{data: "from ledger"}}
        end] do
          idempotency_token = UUID.generate()
          {inserted_user, inserted_token} = insert_user_and_token()
          attrs = build_attrs(idempotency_token, inserted_user, inserted_token)

          inserted_transfer = Transfer.get_or_insert(%{
            idempotency_token: idempotency_token,
            type: Transfer.internal,
            payload: attrs,
            status: Transfer.confirmed,
            ledger_response: %{"data" => "from cached ledger"},
            metadata: %{some: "data"}
          })
          assert inserted_transfer.status == Transfer.confirmed

          {status, _user, _minted_token} = Transaction.process(attrs)
          assert status == :ok

          transfer = Transfer.get(idempotency_token)
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
          idempotency_token = UUID.generate()
          {inserted_user, inserted_token} = insert_user_and_token()
          attrs = build_attrs(idempotency_token, inserted_user, inserted_token)

          inserted_transfer = Transfer.get_or_insert(%{
            idempotency_token: idempotency_token,
            type: Transfer.internal,
            payload: attrs,
            status: Transfer.failed,
            ledger_response: %{"code" => "code!", "description" => "description!"},
            metadata: %{some: "data"}
          })
          assert inserted_transfer.status == Transfer.failed

          {status, _user, _minted_token} = Transaction.process(attrs)
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
          idempotency_token = UUID.generate()
          {inserted_user, inserted_token} = insert_user_and_token()
          attrs = build_attrs(idempotency_token, inserted_user, inserted_token)

          inserted_transfer = Transfer.get_or_insert(%{
            idempotency_token: idempotency_token,
            type: Transfer.internal,
            payload: attrs,
            metadata: %{some: "data"}
          })
          assert inserted_transfer.status == Transfer.pending

          {status, _user, _minted_token} = Transaction.process(attrs)
          assert status == :ok

          transfer = Transfer.get(idempotency_token)
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
          {inserted_user, inserted_token} = insert_user_and_token()
          attrs = build_attrs(idempotency_token, inserted_user, inserted_token)

          {status, code, description} = Transaction.process(attrs)
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
          {inserted_user, inserted_token} = insert_user_and_token()
          attrs = build_attrs(idempotency_token, inserted_user, inserted_token)

          {status, _user, _minted_token} = Transaction.process(attrs)
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
          {inserted_user, inserted_token} = insert_user_and_token()
          attrs = build_attrs(idempotency_token, inserted_user, inserted_token)

          {status, user, minted_token} = Transaction.process(attrs)
          assert status == :ok
          assert user == inserted_user
          assert minted_token == inserted_token
      end
    end
  end
end
