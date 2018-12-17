defmodule EWallet.TransactionConsumptionConsumerGateTest do
  use EWallet.LocalLedgerCase, async: true
  alias Ecto.Adapters.SQL.Sandbox

  alias EWallet.{
    TestEndpoint,
    TransactionConsumptionConsumerGate
  }

  alias EWalletDB.{Token, TransactionConsumption, TransactionRequest, User, Wallet}
  alias ActivityLogger.System

  setup do
    {:ok, pid} = TestEndpoint.start_link()

    on_exit(fn ->
      ref = Process.monitor(pid)
      assert_receive {:DOWN, ^ref, _, _, _}
    end)

    token = insert(:token)
    {:ok, receiver} = :user |> params_for() |> User.insert()
    {:ok, sender} = :user |> params_for() |> User.insert()
    account = Account.get_master_account()
    receiver_wallet = User.get_primary_wallet(receiver)
    sender_wallet = User.get_primary_wallet(sender)
    account_wallet = Account.get_primary_wallet(account)

    mint!(token)

    transaction_request =
      insert(
        :transaction_request,
        type: "receive",
        token_uuid: token.uuid,
        user_uuid: receiver.uuid,
        wallet: receiver_wallet,
        amount: 100_000 * token.subunit_to_unit
      )

    %{
      sender: sender,
      receiver: receiver,
      account: account,
      token: token,
      receiver_wallet: receiver_wallet,
      sender_wallet: sender_wallet,
      account_wallet: account_wallet,
      request: transaction_request
    }
  end

  describe "consume/1 with account_id" do
    test "with nil account_id and no address", meta do
      res =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "account_id" => nil,
          "originator" => %System{}
        })

      assert res == {:error, :account_id_not_found}
    end

    test "with invalid account_id and no address", meta do
      res =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "account_id" => "fake",
          "originator" => %System{}
        })

      assert res == {:error, :account_id_not_found}
    end

    test "with valid account_id and nil address", meta do
      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "account_id" => meta.account.id,
          "address" => nil,
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
    end

    test "with valid account_id and no address", meta do
      {res, request} =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "account_id" => meta.account.id,
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionConsumption{} = request
    end

    test "with valid account_id and a valid address", meta do
      {res, request} =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "account_id" => meta.account.id,
          "address" => meta.account_wallet.address,
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionConsumption{} = request
      assert request.status == "confirmed"
    end

    test "with valid account_id, valid user and a valid address", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      {res, request} =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "account_id" => meta.account.id,
          "provider_user_id" => meta.sender.provider_user_id,
          "address" => meta.sender_wallet.address,
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionConsumption{} = request
      assert request.status == "confirmed"
    end

    test "with valid account_id, valid user but not owned address", meta do
      res =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "account_id" => meta.account.id,
          "provider_user_id" => meta.sender.provider_user_id,
          "address" => meta.account_wallet.address,
          "originator" => %System{}
        })

      assert res == {:error, :user_wallet_mismatch}
    end

    test "with valid account_id and an invalid address", meta do
      res =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "account_id" => meta.account.id,
          "address" => "fake-0000-0000-0000",
          "originator" => %System{}
        })

      assert res == {:error, :account_wallet_not_found}
    end

    test "with valid account_id and an address that does not belong to the account", meta do
      res =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "account_id" => meta.account.id,
          "address" => meta.sender_wallet.address,
          "originator" => %System{}
        })

      assert res == {:error, :account_wallet_mismatch}
    end

    test "works for account even if max_consumptions_per_user is set", meta do
      request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: meta.token.uuid,
          user_uuid: meta.receiver.uuid,
          wallet: meta.receiver_wallet,
          amount: 100_000 * meta.token.subunit_to_unit,
          max_consumptions_per_user: 1
        )

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(%{
          "account_id" => meta.account.id,
          "formatted_transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :ok
      assert consumption.status == "confirmed"

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(%{
          "account_id" => meta.account.id,
          "formatted_transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "1234",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :ok
      assert consumption.status == "confirmed"
    end
  end

  describe "consume/1 with provider_user_id" do
    test "with nil provider_user_id and no address", meta do
      res =
        TransactionConsumptionConsumerGate.consume(%{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "provider_user_id" => nil,
          "originator" => %System{}
        })

      assert res == {:error, :provider_user_id_not_found}
    end

    test "with invalid provider_user_id and no address", meta do
      res =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "provider_user_id" => "fake",
          "originator" => %System{}
        })

      assert res == {:error, :provider_user_id_not_found}
    end

    test "with valid provider_user_id and no address", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      {res, request} =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "provider_user_id" => meta.sender.provider_user_id,
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionConsumption{} = request
    end

    test "with valid provider_user_id and a valid address", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "provider_user_id" => meta.sender.provider_user_id,
          "address" => meta.sender_wallet.address,
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
    end

    test "with valid provider_user_id and an invalid address", meta do
      res =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "provider_user_id" => meta.sender.provider_user_id,
          "address" => "fake-0000-0000-0000",
          "originator" => %System{}
        })

      assert res == {:error, :user_wallet_not_found}
    end

    test "with valid provider_user_id and an address that does not belong to the user", meta do
      res =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "provider_user_id" => meta.sender.provider_user_id,
          "address" => meta.receiver_wallet.address,
          "originator" => %System{}
        })

      assert res == {:error, :user_wallet_mismatch}
    end
  end

  describe "consume/1 with address" do
    test "with nil address", meta do
      res =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "address" => nil,
          "originator" => %System{}
        })

      assert res == {:error, :wallet_not_found}
    end

    test "with a valid address", meta do
      {res, request} =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "address" => meta.account_wallet.address,
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionConsumption{} = request
    end

    test "with an invalid address", meta do
      res =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "address" => "fake-0000-0000-0000",
          "originator" => %System{}
        })

      assert res == {:error, :wallet_not_found}
    end

    test "receives an error when the token is disabled", meta do
      {:ok, token} =
        Token.enable_or_disable(meta.token, %{
          enabled: false,
          originator: %System{}
        })

      {res, code} =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => token.id,
          "address" => meta.account_wallet.address,
          "originator" => %System{}
        })

      assert res == :error
      assert code == :token_is_disabled
    end

    test "receives an error when the wallet is disabled", meta do
      {:ok, wallet} =
        Wallet.insert_secondary_or_burn(%{
          "account_uuid" => meta.account.uuid,
          "name" => "MySecondary",
          "identifier" => "secondary",
          "originator" => %System{}
        })

      {:ok, wallet} =
        Wallet.enable_or_disable(wallet, %{
          enabled: false,
          originator: %System{}
        })

      {res, code} =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "address" => wallet.address,
          "originator" => %System{}
        })

      assert res == :error
      assert code == :wallet_is_disabled
    end
  end

  describe "consume/1 with invalid parameters" do
    test "with invalid parameters", meta do
      res =
        TransactionConsumptionConsumerGate.consume(%{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == {:error, :invalid_parameter}
    end
  end

  describe "consume/2 with user" do
    test "consumes the receive request and transfer the appropriate amount of token with min
    params (and is idempotent)",
         meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      {res, consumption_1} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => meta.request.id,
          "idempotency_token" => "123",
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption_1
      assert consumption_1.transaction_request_uuid == meta.request.uuid

      assert TransactionConsumption.get_final_amount(consumption_1) ==
               100_000 * meta.token.subunit_to_unit

      assert consumption_1.wallet_address == meta.sender_wallet.address

      {res, consumption_2} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => meta.request.id,
          "idempotency_token" => "123",
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption_2
      assert consumption_2.transaction_request_uuid == meta.request.uuid

      assert TransactionConsumption.get_final_amount(consumption_2) ==
               100_000 * meta.token.subunit_to_unit

      assert consumption_2.wallet_address == meta.sender_wallet.address

      assert consumption_1.uuid == consumption_2.uuid
    end

    test "consumes the receive request and transfer the appropriate amount of token with min
    nil params (and is idempotent)",
         meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      {res, consumption_1} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption_1
      assert consumption_1.transaction_request_uuid == meta.request.uuid
      assert consumption_1.amount == nil
      assert consumption_1.wallet_address == meta.sender_wallet.address

      {res, consumption_2} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption_2
      assert consumption_2.transaction_request_uuid == meta.request.uuid
      assert consumption_2.amount == nil
      assert consumption_2.wallet_address == meta.sender_wallet.address

      assert consumption_1.uuid == consumption_2.uuid
    end

    test "fails to consume with insufficient funds (and is idempotent)", meta do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: meta.token.uuid,
          account_uuid: meta.account.uuid,
          wallet: meta.account_wallet,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      {res, consumption_1, error, _error_data} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :error
      assert %TransactionConsumption{} = consumption_1
      assert consumption_1.status == "failed"
      assert error == "insufficient_funds"

      {res, consumption_2, error, _error_data} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :error
      assert %TransactionConsumption{} = consumption_2
      assert consumption_2.status == "failed"
      assert error == "insufficient_funds"

      assert consumption_1.uuid == consumption_2.uuid
    end

    test "consumes an account receive request and transfer the appropriate amount of token with min
    params",
         meta do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: meta.token.uuid,
          account_uuid: meta.account.uuid,
          wallet: meta.account_wallet,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.transaction_request_uuid == transaction_request.uuid
      assert consumption.amount == nil

      assert TransactionConsumption.get_final_amount(consumption) ==
               100_000 * meta.token.subunit_to_unit

      assert consumption.wallet_address == meta.sender_wallet.address
    end

    test "consumes the receive request and transfer the appropriate amount
          of token with all params",
         meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "address" => meta.sender_wallet.address,
          "metadata" => %{},
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.transaction_request_uuid == meta.request.uuid
      assert consumption.amount == 1_000
      assert consumption.wallet_address == meta.sender_wallet.address
    end

    test "returns an 'expired_transaction_request' error when the request is expired", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)
      {:ok, request} = TransactionRequest.expire(meta.request, %System{})

      {res, error} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => request.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "address" => meta.sender_wallet.address,
          "metadata" => %{},
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :error
      assert error == :expired_transaction_request
    end

    test "works with reached max_consumptions_per_user is reached but
          same idempotent token is provided",
         meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: meta.token.uuid,
          user_uuid: meta.receiver.uuid,
          wallet: meta.receiver_wallet,
          amount: 100_000 * meta.token.subunit_to_unit,
          max_consumptions_per_user: 1
        )

      {res, consumption_1} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :ok
      assert consumption_1.status == "confirmed"

      {res, consumption_2} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :ok
      assert consumption_2.status == "confirmed"

      assert consumption_1.uuid == consumption_2.uuid
    end

    test "returns a 'max_consumptions_per_user_reached' error if the maximum number of
          consumptions has been reached for the current user",
         meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: meta.token.uuid,
          user_uuid: meta.receiver.uuid,
          wallet: meta.receiver_wallet,
          amount: 100_000 * meta.token.subunit_to_unit,
          max_consumptions_per_user: 1
        )

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :ok
      assert consumption.status == "confirmed"

      {res, error} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "1234",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :error
      assert error == :max_consumptions_per_user_reached
    end

    test "allows only one consume per user with four consumes at the same time", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      {:ok, request} =
        TransactionRequest.update(meta.request, %{
          max_consumptions_per_user: 1,
          originator: %System{}
        })

      pid = self()

      {:ok, pid_1} =
        Task.start_link(fn ->
          Sandbox.allow(EWalletDB.Repo, pid, self())
          Sandbox.allow(LocalLedgerDB.Repo, pid, self())

          assert_receive :start_consume, 5000

          {res, response} =
            TransactionConsumptionConsumerGate.consume(meta.sender, %{
              "formatted_transaction_request_id" => request.id,
              "correlation_id" => nil,
              "amount" => nil,
              "address" => nil,
              "metadata" => nil,
              "idempotency_token" => "1",
              "token_id" => nil,
              "originator" => %System{}
            })

          send(pid, {:updated_1, res, response})
        end)

      {:ok, pid_2} =
        Task.start_link(fn ->
          Sandbox.allow(EWalletDB.Repo, pid, self())
          Sandbox.allow(LocalLedgerDB.Repo, pid, self())

          assert_receive :start_consume, 5000

          {res, response} =
            TransactionConsumptionConsumerGate.consume(meta.sender, %{
              "formatted_transaction_request_id" => request.id,
              "correlation_id" => nil,
              "amount" => nil,
              "address" => nil,
              "metadata" => nil,
              "idempotency_token" => "2",
              "token_id" => nil,
              "originator" => %System{}
            })

          send(pid, {:updated_2, res, response})
        end)

      {:ok, pid_3} =
        Task.start_link(fn ->
          Sandbox.allow(EWalletDB.Repo, pid, self())
          Sandbox.allow(LocalLedgerDB.Repo, pid, self())

          assert_receive :start_consume, 5000

          {res, response} =
            TransactionConsumptionConsumerGate.consume(meta.sender, %{
              "formatted_transaction_request_id" => request.id,
              "correlation_id" => nil,
              "amount" => nil,
              "address" => nil,
              "metadata" => nil,
              "idempotency_token" => "3",
              "token_id" => nil,
              "originator" => %System{}
            })

          send(pid, {:updated_3, res, response})
        end)

      {:ok, pid_4} =
        Task.start_link(fn ->
          Sandbox.allow(EWalletDB.Repo, pid, self())
          Sandbox.allow(LocalLedgerDB.Repo, pid, self())

          assert_receive :start_consume, 5000

          {res, response} =
            TransactionConsumptionConsumerGate.consume(meta.sender, %{
              "formatted_transaction_request_id" => request.id,
              "correlation_id" => nil,
              "amount" => nil,
              "address" => nil,
              "metadata" => nil,
              "idempotency_token" => "4",
              "token_id" => nil,
              "originator" => %System{}
            })

          send(pid, {:updated_4, res, response})
        end)

      send(pid_2, :start_consume)
      send(pid_1, :start_consume)
      send(pid_3, :start_consume)
      send(pid_4, :start_consume)

      assert_receive {:updated_1, _res, response_1}, 5000
      assert_receive {:updated_2, _res, response_2}, 5000
      assert_receive {:updated_3, _res, response_3}, 5000
      assert_receive {:updated_4, _res, response_4}, 5000

      acc = %{errors: 0, consumptions: 0}

      counts =
        Enum.reduce([response_1, response_2, response_3, response_4], acc, fn response, acc ->
          case response do
            :max_consumptions_per_user_reached ->
              Map.put(acc, :errors, acc[:errors] + 1)

            _ ->
              Map.put(acc, :consumptions, acc[:consumptions] + 1)
          end
        end)

      assert counts == %{
               consumptions: 1,
               errors: 3
             }

      consumptions = TransactionConsumption |> EWalletDB.Repo.all()
      assert length(consumptions) == 1
      consumption = Enum.at(consumptions, 0)
      assert consumption.status == "confirmed"
    end

    test "works and returns the previous consumption with max_consumptions and
         same idempotency_token",
         meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      {:ok, request} =
        TransactionRequest.update(meta.request, %{
          max_consumptions: 1,
          originator: %System{}
        })

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :ok
      assert consumption.status == "confirmed"

      {res, consumption_2} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :ok
      assert consumption_2.status == "confirmed"
      assert consumption.uuid == consumption_2.uuid
    end

    test "returns a 'max_consumptions_reached' error if the maximum number of
          consumptions has been reached",
         meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      {:ok, request} =
        TransactionRequest.update(meta.request, %{
          max_consumptions: 1,
          originator: %System{}
        })

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :ok
      assert consumption.status == "confirmed"

      {res, error} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "1234",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :error
      assert error == :max_consumptions_reached
    end

    test "allows only one consume with four consumes at the same time", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      {:ok, request} =
        TransactionRequest.update(meta.request, %{
          max_consumptions: 1,
          originator: %System{}
        })

      pid = self()

      {:ok, pid_1} =
        Task.start_link(fn ->
          Sandbox.allow(EWalletDB.Repo, pid, self())
          Sandbox.allow(LocalLedgerDB.Repo, pid, self())

          assert_receive :start_consume, 5000

          {res, response} =
            TransactionConsumptionConsumerGate.consume(meta.sender, %{
              "formatted_transaction_request_id" => request.id,
              "correlation_id" => nil,
              "amount" => nil,
              "address" => nil,
              "metadata" => nil,
              "idempotency_token" => "1",
              "token_id" => nil,
              "originator" => %System{}
            })

          send(pid, {:updated_1, res, response})
        end)

      {:ok, pid_2} =
        Task.start_link(fn ->
          Sandbox.allow(EWalletDB.Repo, pid, self())
          Sandbox.allow(LocalLedgerDB.Repo, pid, self())

          assert_receive :start_consume, 5000

          {res, response} =
            TransactionConsumptionConsumerGate.consume(meta.sender, %{
              "formatted_transaction_request_id" => request.id,
              "correlation_id" => nil,
              "amount" => nil,
              "address" => nil,
              "metadata" => nil,
              "idempotency_token" => "2",
              "token_id" => nil,
              "originator" => %System{}
            })

          send(pid, {:updated_2, res, response})
        end)

      {:ok, pid_3} =
        Task.start_link(fn ->
          Sandbox.allow(EWalletDB.Repo, pid, self())
          Sandbox.allow(LocalLedgerDB.Repo, pid, self())

          assert_receive :start_consume, 5000

          {res, response} =
            TransactionConsumptionConsumerGate.consume(meta.sender, %{
              "formatted_transaction_request_id" => request.id,
              "correlation_id" => nil,
              "amount" => nil,
              "address" => nil,
              "metadata" => nil,
              "idempotency_token" => "3",
              "token_id" => nil,
              "originator" => %System{}
            })

          send(pid, {:updated_3, res, response})
        end)

      {:ok, pid_4} =
        Task.start_link(fn ->
          Sandbox.allow(EWalletDB.Repo, pid, self())
          Sandbox.allow(LocalLedgerDB.Repo, pid, self())

          assert_receive :start_consume, 5000

          {res, response} =
            TransactionConsumptionConsumerGate.consume(meta.sender, %{
              "formatted_transaction_request_id" => request.id,
              "correlation_id" => nil,
              "amount" => nil,
              "address" => nil,
              "metadata" => nil,
              "idempotency_token" => "4",
              "token_id" => nil,
              "originator" => %System{}
            })

          send(pid, {:updated_4, res, response})
        end)

      send(pid_2, :start_consume)
      send(pid_1, :start_consume)
      send(pid_3, :start_consume)
      send(pid_4, :start_consume)

      assert_receive {:updated_1, _res, _response}, 5000
      assert_receive {:updated_2, _res, _response}, 5000
      assert_receive {:updated_3, _res, _response}, 5000
      assert_receive {:updated_4, _res, response}, 5000
      assert response == :max_consumptions_reached

      consumptions = TransactionConsumption |> EWalletDB.Repo.all()
      assert length(consumptions) == 1
    end

    test "proceeds if the maximum number of consumptions hasn't been reached and
          increment it",
         meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      {:ok, request} =
        TransactionRequest.update(meta.request, %{
          max_consumptions: 2,
          originator: %System{}
        })

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :ok
      assert consumption.status == "confirmed"

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "1234",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :ok
      assert consumption.status == "confirmed"

      request = TransactionRequest.get(request.id)
      assert request.status == "expired"
      assert request.expiration_reason == "max_consumptions_reached"
    end

    # require_confirmation + max consumptions?
    test "prevents consumptions when max consumption has been reached with confirmed ones",
         meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      {:ok, request} =
        TransactionRequest.update(meta.request, %{
          max_consumptions: 1,
          originator: %System{}
        })

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => request.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "address" => meta.sender_wallet.address,
          "metadata" => %{},
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :ok
      assert consumption.status == "confirmed"

      {res, error} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "1234",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :error
      assert error == :max_consumptions_reached
    end

    test "returns a pending request with no transfer is the request requires confirmation
         (and is idempotent)",
         meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      {:ok, request} =
        TransactionRequest.update(meta.request, %{
          require_confirmation: true,
          originator: %System{}
        })

      {res, consumption_1} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => request.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "address" => meta.sender_wallet.address,
          "metadata" => %{},
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :ok
      assert consumption_1.status == "pending"

      {res, consumption_2} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => request.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "address" => meta.sender_wallet.address,
          "metadata" => %{},
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :ok
      assert consumption_2.status == "pending"

      assert consumption_1.uuid == consumption_2.uuid
    end

    test "sets an expiration date for consumptions if there is a consumption lifetime provided",
         meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      {:ok, request} =
        TransactionRequest.update(meta.request, %{
          require_confirmation: true,
          # 60 seconds
          consumption_lifetime: 60_000,
          originator: %System{}
        })

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => request.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "address" => meta.sender_wallet.address,
          "metadata" => %{},
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :ok
      assert consumption.status == "pending"
      assert consumption.expiration_date != nil
      assert NaiveDateTime.compare(consumption.expiration_date, NaiveDateTime.utc_now()) == :gt
    end

    test "does notset an expiration date for consumptions if the request is not require_confirmation",
         meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      {:ok, request} =
        TransactionRequest.update(meta.request, %{
          # 60 seconds
          consumption_lifetime: 60_000,
          originator: %System{}
        })

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => request.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "address" => meta.sender_wallet.address,
          "metadata" => %{},
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :ok
      assert consumption.status == "confirmed"
      assert consumption.expiration_date == nil
    end

    test "overrides the amount if the request amount is overridable", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      {:ok, request} =
        TransactionRequest.update(meta.request, %{
          allow_amount_override: true,
          originator: %System{}
        })

      {res, consumption} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => request.id,
          "correlation_id" => "123",
          "amount" => 1_123,
          "address" => meta.sender_wallet.address,
          "metadata" => %{},
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :ok
      assert consumption.status == "confirmed"
      assert consumption.amount == 1_123
    end

    test "returns an 'unauthorized_amount_override' error if the consumption tries to
          illegally override the amount",
         meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      {:ok, request} =
        TransactionRequest.update(meta.request, %{
          allow_amount_override: false,
          originator: %System{}
        })

      {res, error} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => request.id,
          "correlation_id" => "123",
          "amount" => 1_123,
          "address" => meta.sender_wallet.address,
          "metadata" => %{},
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :error
      assert error == :unauthorized_amount_override
    end

    test "returns an error for user consumption with different tokens", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)
      different_token = insert(:token)

      {res, error} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => "123",
          "amount" => 0,
          "address" => meta.sender_wallet.address,
          "metadata" => %{},
          "idempotency_token" => "123",
          "token_id" => different_token.id
        })

      assert res == :error
      assert error == :exchange_client_not_allowed
    end

    test "returns an error if the consumption tries to set an amount equal to 0", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      {res, changeset} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => "123",
          "amount" => 0,
          "address" => meta.sender_wallet.address,
          "metadata" => %{},
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :error

      assert changeset.errors == [
               amount: {"must be greater than %{number}", [validation: :number, number: 0]}
             ]
    end

    test "returns the same consumption when idempency_token is the same", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      {res, consumption_1} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :ok

      {res, consumption_2} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :ok
      assert consumption_1.id == consumption_2.id
      assert consumption_1.idempotency_token == consumption_2.idempotency_token
    end

    test "returns 'invalid_parameter' when amount is not set", meta do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: meta.token.uuid,
          user_uuid: meta.receiver.uuid,
          wallet: meta.receiver_wallet,
          amount: nil
        )

      {res, code, desc} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :error
      assert code == :invalid_parameter

      assert desc ==
               "Invalid parameter provided. `amount` is required for transaction consumption."
    end

    test "returns 'user_wallet_not_found' when address is invalid", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)

      {res, error} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => "fake-0000-0000-0000",
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :error
      assert error == :user_wallet_not_found
    end

    test "returns 'wallet_not_found' when address does not belong to sender", meta do
      initialize_wallet(meta.sender_wallet, 200_000, meta.token)
      wallet = insert(:wallet)

      {res, error} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "formatted_transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => wallet.address,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "originator" => %System{}
        })

      assert res == :error
      assert error == :user_wallet_mismatch
    end

    test "returns 'invalid parameter' when not all attributes are provided", meta do
      {res, error} =
        TransactionConsumptionConsumerGate.consume(meta.sender, %{
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "originator" => %System{}
        })

      assert res == :error
      assert error == :invalid_parameter
    end
  end
end
