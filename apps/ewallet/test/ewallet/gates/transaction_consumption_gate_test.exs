defmodule EWallet.TransactionConsumptionGateTest do
 use EWallet.LocalLedgerCase, async: true
 alias EWallet.TransactionConsumptionGate
 alias EWalletDB.{User, TransactionRequestConsumption}

  setup do
    minted_token            = insert(:minted_token)
    {:ok, receiver}         = :user |> params_for() |> User.insert()
    {:ok, sender}           = :user |> params_for() |> User.insert()
    account                 = Account.get_master_account()
    receiver_balance        = User.get_primary_balance(receiver)
    sender_balance          = User.get_primary_balance(sender)
    account_balance = Account.get_primary_balance(account)

    mint!(minted_token)

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
      account: account,
      minted_token: minted_token,
      receiver_balance: receiver_balance,
      sender_balance: sender_balance,
      account_balance: account_balance,
      request: transaction_request
    }
  end

  describe "consume/1 with account_id" do
    test "with nil account_id and no address", meta do
      res = TransactionConsumptionGate.consume(%{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil,
        "account_id" => nil
      }, nil)

      assert res == {:error, :account_id_not_found}
    end

    test "with invalid account_id and no address", meta do
      res = TransactionConsumptionGate.consume(%{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil,
        "account_id" => "fake"
      }, nil)

      assert res == {:error, :account_id_not_found}
    end

    test "with valid account_id and nil address", meta do
      {res, consumption} = TransactionConsumptionGate.consume(%{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil,
        "account_id" => meta.account.id,
        "address" => nil
      }, nil)

      assert res == :ok
      assert %TransactionRequestConsumption{} = consumption
    end

    test "with valid account_id and no address", meta do
      {res, request} = TransactionConsumptionGate.consume(%{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil,
        "account_id" => meta.account.id
      }, nil)

      assert res == :ok
      assert %TransactionRequestConsumption{} = request
    end

    test "with valid account_id and a valid address", meta do
      {res, request} = TransactionConsumptionGate.consume(%{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil,
        "account_id" => meta.account.id,
        "address" => meta.account_balance.address
      }, nil)

      assert res == :ok
      assert %TransactionRequestConsumption{} = request
      assert request.status == "confirmed"
    end

    test "with valid account_id and an invalid address", meta do
      res = TransactionConsumptionGate.consume(%{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil,
        "account_id" => meta.account.id,
        "address" => "fake"
      }, nil)

      assert res == {:error, :balance_not_found}
    end

    test "with valid account_id and an address that does not belong to the account", meta do
      res = TransactionConsumptionGate.consume(%{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil,
        "account_id" => meta.account.id,
        "address" => meta.sender_balance.address
      }, nil)

      assert res == {:error, :account_balance_mismatch}
    end
  end

  describe "consume/1 with provider_user_id" do
    test "with nil provider_user_id and no address", meta do
      res = TransactionConsumptionGate.consume(%{
        "type" => "receive",
        "token_id" => meta.minted_token.friendly_id,
        "correlation_id" => "123",
        "amount" => 1_000,
        "provider_user_id" => nil
      }, nil)

      assert res == {:error, :provider_user_id_not_found}
    end

    test "with invalid provider_user_id and no address", meta do
      res = TransactionConsumptionGate.consume(%{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil,
        "provider_user_id" => "fake"
      }, nil)

      assert res == {:error, :provider_user_id_not_found}
    end

    test "with valid provider_user_id and no address", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, request} = TransactionConsumptionGate.consume(%{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil,
        "provider_user_id" => meta.sender.provider_user_id
      }, nil)

      assert res == :ok
      assert %TransactionRequestConsumption{} = request
    end

    test "with valid provider_user_id and a valid address", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, request} = TransactionConsumptionGate.consume(%{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil,
        "provider_user_id" => meta.sender.provider_user_id,
        "address" => meta.sender_balance.address
      }, nil)

      assert res == :ok
      assert %TransactionRequestConsumption{} = request
    end

    test "with valid provider_user_id and an invalid address", meta do
      res = TransactionConsumptionGate.consume(%{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil,
        "provider_user_id" => meta.sender.provider_user_id,
        "address" => "fake"
      }, nil)

      assert res == {:error, :balance_not_found}
    end

    test "with valid provider_user_id and an address that does not belong to the user", meta do
      res = TransactionConsumptionGate.consume(%{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil,
        "provider_user_id" => meta.sender.provider_user_id,
        "address" => meta.receiver_balance.address
      }, nil)

      assert res == {:error, :user_balance_mismatch}
    end
  end

  describe "consume/1 with address" do
    test "with nil address", meta do
      res = TransactionConsumptionGate.consume(%{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil,
        "address" => nil
      }, nil)

      assert res == {:error, :balance_not_found}
    end

    test "with a valid address", meta do
      {res, request} = TransactionConsumptionGate.consume(%{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil,
        "address" => meta.account_balance.address
      }, nil)

      assert res == :ok
      assert %TransactionRequestConsumption{} = request
    end

    test "with an invalid address", meta do
      res = TransactionConsumptionGate.consume(%{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil,
        "address" => "fake"
      }, nil)

      assert res == {:error, :balance_not_found}
    end
  end

  describe "consume/1 with invalid parameters" do
    test "with invalid parameters", meta do
      res = TransactionConsumptionGate.consume(%{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil
      }, nil)

      assert res == {:error, :invalid_parameter}
    end
  end

  describe "consume/2" do
    test "consumes the receive request and transfer the appropriate amount of token with min
    params", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, consumption} = TransactionConsumptionGate.consume(meta.sender, %{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "address" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil
      }, nil)

      assert res == :ok
      assert %TransactionRequestConsumption{} = consumption
      assert consumption.transaction_request_id == meta.request.id
      assert consumption.amount == meta.request.amount
      assert consumption.balance_address == meta.sender_balance.address
    end

    test "consumes an account receive request and transfer the appropriate amount of token with min
    params", meta do
      transaction_request = insert(:transaction_request,
        type: "receive",
        minted_token_id: meta.minted_token.id,
        account_id: meta.account.id,
        balance: meta.account_balance,
        amount: 100_000 * meta.minted_token.subunit_to_unit
      )

      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, consumption} = TransactionConsumptionGate.consume(meta.sender, %{
        "transaction_request_id" => transaction_request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "address" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil
      }, nil)

      assert res == :ok
      assert %TransactionRequestConsumption{} = consumption
      assert consumption.transaction_request_id == transaction_request.id
      assert consumption.amount == meta.request.amount
      assert consumption.balance_address == meta.sender_balance.address
    end

    test "consumes the receive request and transfer the appropriate amount
          of token with all params", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, consumption} = TransactionConsumptionGate.consume(meta.sender, %{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => "123",
        "amount" => 1_000,
        "address" => meta.sender_balance.address,
        "metadata" => %{},
        "idempotency_token" => "123",
        "token_id" => nil
      }, nil)

      assert res == :ok
      assert %TransactionRequestConsumption{} = consumption
      assert consumption.transaction_request_id == meta.request.id
      assert consumption.amount == 1_000
      assert consumption.balance_address == meta.sender_balance.address
    end

    test "returns the same consumption when idempency_token is the same", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, consumption_1} = TransactionConsumptionGate.consume(meta.sender, %{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "address" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil
      }, nil)
      assert res == :ok

      {res, consumption_2} = TransactionConsumptionGate.consume(meta.sender, %{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "address" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil
      }, nil)

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
      }, nil)

      assert error == :error
      assert changeset.errors ==  [amount: {"can't be blank", [validation: :required]}]
    end

    test "returns 'balance_not_found' when address is invalid", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, error} = TransactionConsumptionGate.consume(meta.sender, %{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "address" => "fake",
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil
      }, nil)

      assert res == :error
      assert error == :balance_not_found
    end

    test "returns 'balance_not_found' when address does not belong to sender", meta do
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
      }, nil)

      assert res == :error
      assert error == :user_balance_mismatch
    end

    test "returns 'invalid parameter' when not all attributes are provided", meta do
      {res, error} = TransactionConsumptionGate.consume(meta.sender, %{
        "correlation_id" => nil,
        "amount" => nil,
        "metadata" => nil
      }, nil)

      assert res == :error
      assert error == :invalid_parameter
    end
  end

  describe "get/1" do
    test "returns the consumption do when given valid ID", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, consumption} = TransactionConsumptionGate.consume(meta.sender, %{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "address" => nil,
        "metadata" => nil,
        "idempotency_token" => "123",
        "token_id" => nil
      }, nil)

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
