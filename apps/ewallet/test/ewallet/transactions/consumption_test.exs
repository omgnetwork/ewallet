defmodule EWallet.Transactions.ConsumptionTest do
 use EWallet.LocalLedgerCase, async: true
 alias EWallet.Transactions.Consumption
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

      {res, consumption} = Consumption.consume(meta.sender, "123", %{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "address" => nil,
        "metadata" => nil
      })

      assert res == :ok
      assert %TransactionRequestConsumption{} = consumption
      assert consumption.transaction_request_id == meta.request.id
      assert consumption.amount == meta.request.amount
      assert consumption.balance_address == meta.sender_balance.address
    end

    test "consumes the receive request and transfer the appropriate amount of token with all params",
    meta do
      mint!(meta.minted_token)
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, consumption} = Consumption.consume(meta.sender, "123", %{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => "123",
        "amount" => 1_000,
        "address" => meta.sender_balance.address,
        "metadata" => %{}
      })

      assert res == :ok
      assert %TransactionRequestConsumption{} = consumption
      assert consumption.transaction_request_id == meta.request.id
      assert consumption.amount == 1_000
      assert consumption.balance_address == meta.sender_balance.address
    end

    test "returns 'balance_not_found' when address is invalid", meta do
      mint!(meta.minted_token)
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, error} = Consumption.consume(meta.sender, "123", %{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "address" => "fake",
        "metadata" => nil
      })

      assert res == :error
      assert error == :balance_not_found
    end

    test "returns 'balance_not_found' when address does not belong to sender", meta do
      mint!(meta.minted_token)
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)
      balance = insert(:balance)

      {res, error} = Consumption.consume(meta.sender, "123", %{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "address" => balance.address,
        "metadata" => nil
      })

      assert res == :error
      assert error == :user_balance_mismatch
    end

    test "returns 'invalid parameter' when not all attributes are provided", meta do
      {res, error} = Consumption.consume(meta.sender, "123", %{
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

      {res, consumption} = Consumption.consume(meta.sender, "123", %{
        "transaction_request_id" => meta.request.id,
        "correlation_id" => nil,
        "amount" => nil,
        "address" => nil,
        "metadata" => nil
      })

      assert res == :ok
      assert %TransactionRequestConsumption{} = Consumption.get(consumption.id)
    end

    test "returns nil when given nil" do
      assert Consumption.get(nil) == nil
    end

    test "returns nil when given invalid UUID" do
      assert Consumption.get("123") == nil
    end
  end
end
