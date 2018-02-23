defmodule EWallet.TransactionConsumptionGateTest do
 use EWallet.LocalLedgerCase, async: true
 alias EWallet.TransactionConsumptionGate
 alias EWalletDB.{User, TransactionRequestConsumption}

  setup do
    minted_token            = insert(:minted_token)
    {:ok, receiver}         = :user |> params_for() |> User.insert()
    {:ok, sender}           = :user |> params_for() |> User.insert()
    receiver_balance        = User.get_primary_balance(receiver)
    sender_balance          = User.get_primary_balance(sender)

    transaction_request = insert(:transaction_request,
      type: "receive",
      minted_token_id: minted_token.id,
      user_id: receiver.id,
      balance: receiver_balance,
      amount: 100_000 * minted_token.subunit_to_unit
    )

    %{
      sender: sender,
      receiver: receiver,
      minted_token: minted_token,
      receiver_balance: receiver_balance,
      sender_balance: sender_balance,
      request: transaction_request
    }
  end

  describe "consume/3" do
    test "consumes the receive request and transfer the appropriate amount of token with min
    params", meta do
      mint!(meta.minted_token)
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, consumption} = TransactionConsumptionGate.consume(meta.sender, %{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "address" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil
      })

      assert res == :ok
      assert %TransactionRequestConsumption{} = consumption
      assert consumption.transaction_request_id == meta.request.id
      assert consumption.amount == meta.request.amount
      assert consumption.balance_address == meta.sender_balance.address
    end

    test "consumes the receive request and transfer the appropriate amount
          of token with all params", meta do
      mint!(meta.minted_token)
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, consumption} = TransactionConsumptionGate.consume(meta.sender, %{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => "123",
        "amount" => 1_000,
        "address" => meta.sender_balance.address,
        "metadata" => %{},
        "idempotency_token" => "123",
        "token_id" => nil
      })

      assert res == :ok
      assert %TransactionRequestConsumption{} = consumption
      assert consumption.transaction_request_id == meta.request.id
      assert consumption.amount == 1_000
      assert consumption.balance_address == meta.sender_balance.address
    end

    test "returns the same consumption when idempency_token is the same", meta do
      mint!(meta.minted_token)
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, consumption_1} = TransactionConsumptionGate.consume(meta.sender, %{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "address" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil
      })
      assert res == :ok

      {res, consumption_2} = TransactionConsumptionGate.consume(meta.sender, %{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "address" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil
      })

      assert res == :ok
      assert consumption_1.id == consumption_2.id
      assert consumption_1.idempotency_token == consumption_2.idempotency_token
    end

    test "returns 'invalid_parameter' when amount is not set", meta do
      transaction_request = insert(:transaction_request,
        type: "receive",
        minted_token_id: meta.minted_token.id,
        user_id: meta.receiver.id,
        balance: meta.receiver_balance,
        amount: nil
      )

      {error, changeset} = TransactionConsumptionGate.consume(meta.sender, %{
        "transaction_request_id" => transaction_request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "address" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil
      })

      assert error == :error
      assert changeset.errors ==  [amount: {"can't be blank", [validation: :required]}]
    end

    test "returns 'balance_not_found' when address is invalid", meta do
      mint!(meta.minted_token)
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, error} = TransactionConsumptionGate.consume(meta.sender, %{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "address" => "fake",
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil
      })

      assert res == :error
      assert error == :balance_not_found
    end

    test "returns 'balance_not_found' when address does not belong to sender", meta do
      mint!(meta.minted_token)
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)
      balance = insert(:balance)

      {res, error} = TransactionConsumptionGate.consume(meta.sender, %{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "address" => balance.address,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil
      })

      assert res == :error
      assert error == :user_balance_mismatch
    end

    test "returns 'invalid parameter' when not all attributes are provided", meta do
      {res, error} = TransactionConsumptionGate.consume(meta.sender, %{
        "correlation_id" => nil,
        "amount" => nil,
        "metadata" => nil
      })

      assert res == :error
      assert error == :invalid_parameter
    end
  end

  describe "get/1" do
    test "returns the consumption do when given valid ID", meta do
      mint!(meta.minted_token)
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, consumption} = TransactionConsumptionGate.consume(meta.sender, %{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "address" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil
      })

      assert res == :ok
      assert {:ok, consumption} = TransactionConsumptionGate.get(consumption.id)
      assert %TransactionRequestConsumption{} = consumption
    end

    test "returns nil when given nil" do
      assert TransactionConsumptionGate.get(nil) ==
             {:error, :transaction_request_consumption_not_found}
    end

    test "returns nil when given invalid UUID" do
      assert TransactionConsumptionGate.get("123") ==
             {:error, :transaction_request_consumption_not_found}
    end
  end
end
