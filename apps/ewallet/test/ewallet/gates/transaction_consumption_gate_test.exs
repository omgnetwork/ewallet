defmodule EWallet.TransactionConsumptionGateTest do
  use EWallet.LocalLedgerCase, async: true
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID
  alias EWallet.{TestEndpoint, TransactionRequestGate, TransactionConsumptionGate}
  alias EWalletDB.{User, TransactionConsumption, TransactionRequest}

  setup do
    {:ok, _} = TestEndpoint.start_link()

    minted_token = insert(:minted_token)
    {:ok, receiver} = :user |> params_for() |> User.insert()
    {:ok, sender} = :user |> params_for() |> User.insert()
    account = Account.get_master_account()
    receiver_balance = User.get_primary_balance(receiver)
    sender_balance = User.get_primary_balance(sender)
    account_balance = Account.get_primary_balance(account)

    mint!(minted_token)

    transaction_request =
      insert(
        :transaction_request,
        type: "receive",
        minted_token_uuid: minted_token.uuid,
        user_uuid: receiver.uuid,
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
      res =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "account_id" => nil
        })

      assert res == {:error, :account_id_not_found}
    end

    test "with invalid account_id and no address", meta do
      res =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "account_id" => "fake"
        })

      assert res == {:error, :account_id_not_found}
    end

    test "with valid account_id and nil address", meta do
      {res, consumption} =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "account_id" => meta.account.id,
          "address" => nil
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
    end

    test "with valid account_id and no address", meta do
      {res, request} =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "account_id" => meta.account.id
        })

      assert res == :ok
      assert %TransactionConsumption{} = request
    end

    test "with valid account_id and a valid address", meta do
      {res, request} =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "account_id" => meta.account.id,
          "address" => meta.account_balance.address
        })

      assert res == :ok
      assert %TransactionConsumption{} = request
      assert request.status == "confirmed"
    end

    test "with valid account_id, valid user and a valid address", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, request} =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "account_id" => meta.account.id,
          "provider_user_id" => meta.sender.provider_user_id,
          "address" => meta.sender_balance.address
        })

      assert res == :ok
      assert %TransactionConsumption{} = request
      assert request.status == "confirmed"
    end

    test "with valid account_id, valid user but not owned address", meta do
      res =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "account_id" => meta.account.id,
          "provider_user_id" => meta.sender.provider_user_id,
          "address" => meta.account_balance.address
        })

      assert res == {:error, :user_balance_mismatch}
    end

    test "with valid account_id and an invalid address", meta do
      res =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "account_id" => meta.account.id,
          "address" => "fake"
        })

      assert res == {:error, :balance_not_found}
    end

    test "with valid account_id and an address that does not belong to the account", meta do
      res =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "account_id" => meta.account.id,
          "address" => meta.sender_balance.address
        })

      assert res == {:error, :account_balance_mismatch}
    end
  end

  describe "consume/1 with provider_user_id" do
    test "with nil provider_user_id and no address", meta do
      res =
        TransactionConsumptionGate.consume(%{
          "type" => "receive",
          "token_id" => meta.minted_token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "provider_user_id" => nil
        })

      assert res == {:error, :provider_user_id_not_found}
    end

    test "with invalid provider_user_id and no address", meta do
      res =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "provider_user_id" => "fake"
        })

      assert res == {:error, :provider_user_id_not_found}
    end

    test "with valid provider_user_id and no address", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, request} =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "provider_user_id" => meta.sender.provider_user_id
        })

      assert res == :ok
      assert %TransactionConsumption{} = request
    end

    test "with valid provider_user_id and a valid address", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, request} =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "provider_user_id" => meta.sender.provider_user_id,
          "address" => meta.sender_balance.address
        })

      assert res == :ok
      assert %TransactionConsumption{} = request
    end

    test "with valid provider_user_id and an invalid address", meta do
      res =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "provider_user_id" => meta.sender.provider_user_id,
          "address" => "fake"
        })

      assert res == {:error, :balance_not_found}
    end

    test "with valid provider_user_id and an address that does not belong to the user", meta do
      res =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "provider_user_id" => meta.sender.provider_user_id,
          "address" => meta.receiver_balance.address
        })

      assert res == {:error, :user_balance_mismatch}
    end
  end

  describe "consume/1 with address" do
    test "with nil address", meta do
      res =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "address" => nil
        })

      assert res == {:error, :balance_not_found}
    end

    test "with a valid address", meta do
      {res, request} =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "address" => meta.account_balance.address
        })

      assert res == :ok
      assert %TransactionConsumption{} = request
    end

    test "with an invalid address", meta do
      res =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "address" => "fake"
        })

      assert res == {:error, :balance_not_found}
    end
  end

  describe "consume/1 with invalid parameters" do
    test "with invalid parameters", meta do
      res =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil
        })

      assert res == {:error, :invalid_parameter}
    end
  end

  describe "consume/2 with balance" do
    test "consumes the receive request and transfer the appropriate amount of token with min
    params", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, consumption} =
        TransactionConsumptionGate.consume(meta.sender, %{
          "transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.transaction_request_uuid == meta.request.uuid
      assert consumption.amount == meta.request.amount
      assert consumption.balance_address == meta.sender_balance.address
    end

    test "consumes an account receive request and transfer the appropriate amount of token with min
    params", meta do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          minted_token_uuid: meta.minted_token.uuid,
          account_uuid: meta.account.uuid,
          balance: meta.account_balance,
          amount: 100_000 * meta.minted_token.subunit_to_unit
        )

      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, consumption} =
        TransactionConsumptionGate.consume(meta.sender, %{
          "transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.transaction_request_uuid == transaction_request.uuid
      assert consumption.amount == meta.request.amount
      assert consumption.balance_address == meta.sender_balance.address
    end

    test "consumes the receive request and transfer the appropriate amount
          of token with all params", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, consumption} =
        TransactionConsumptionGate.consume(meta.sender, %{
          "transaction_request_id" => meta.request.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "address" => meta.sender_balance.address,
          "metadata" => %{},
          "idempotency_token" => "123",
          "token_id" => nil
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.transaction_request_uuid == meta.request.uuid
      assert consumption.amount == 1_000
      assert consumption.balance_address == meta.sender_balance.address
    end

    test "returns an 'expired_transaction_request' error when the request is expired", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)
      {:ok, request} = TransactionRequest.expire(meta.request)

      {res, error} =
        TransactionConsumptionGate.consume(meta.sender, %{
          "transaction_request_id" => request.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "address" => meta.sender_balance.address,
          "metadata" => %{},
          "idempotency_token" => "123",
          "token_id" => nil
        })

      assert res == :error
      assert error == :expired_transaction_request
    end

    test "returns a 'max_consumptions_reached' error if the maximum number of
          consumptions has been reached", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)
      {:ok, request} = TransactionRequest.update(meta.request, %{max_consumptions: 1})

      {res, consumption} =
        TransactionConsumptionGate.consume(meta.sender, %{
          "transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil
        })

      assert res == :ok
      assert consumption.status == "confirmed"

      {res, error} =
        TransactionConsumptionGate.consume(meta.sender, %{
          "transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "1234",
          "token_id" => nil
        })

      assert res == :error
      assert error == :max_consumptions_reached
    end

    test "allows only one consume with two consume at the same time", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)
      {:ok, request} = TransactionRequest.update(meta.request, %{max_consumptions: 1})

      pid = self()

      {:ok, pid_1} =
        Task.start_link(fn ->
          Sandbox.allow(EWalletDB.Repo, pid, self())
          Sandbox.allow(LocalLedgerDB.Repo, pid, self())

          assert_receive :start_consume, 5000

          {res, response} =
            TransactionConsumptionGate.consume(meta.sender, %{
              "transaction_request_id" => request.id,
              "correlation_id" => nil,
              "amount" => nil,
              "address" => nil,
              "metadata" => nil,
              "idempotency_token" => "1",
              "token_id" => nil
            })

          send(pid, {:updated_1, res, response})
        end)

      {:ok, pid_2} =
        Task.start_link(fn ->
          Sandbox.allow(EWalletDB.Repo, pid, self())
          Sandbox.allow(LocalLedgerDB.Repo, pid, self())

          assert_receive :start_consume, 5000

          {res, response} =
            TransactionConsumptionGate.consume(meta.sender, %{
              "transaction_request_id" => request.id,
              "correlation_id" => nil,
              "amount" => nil,
              "address" => nil,
              "metadata" => nil,
              "idempotency_token" => "2",
              "token_id" => nil
            })

          send(pid, {:updated_2, res, response})
        end)

      {:ok, pid_3} =
        Task.start_link(fn ->
          Sandbox.allow(EWalletDB.Repo, pid, self())
          Sandbox.allow(LocalLedgerDB.Repo, pid, self())

          assert_receive :start_consume, 5000

          {res, response} =
            TransactionConsumptionGate.consume(meta.sender, %{
              "transaction_request_id" => request.id,
              "correlation_id" => nil,
              "amount" => nil,
              "address" => nil,
              "metadata" => nil,
              "idempotency_token" => "3",
              "token_id" => nil
            })

          send(pid, {:updated_3, res, response})
        end)

      {:ok, pid_4} =
        Task.start_link(fn ->
          Sandbox.allow(EWalletDB.Repo, pid, self())
          Sandbox.allow(LocalLedgerDB.Repo, pid, self())

          assert_receive :start_consume, 5000

          {res, response} =
            TransactionConsumptionGate.consume(meta.sender, %{
              "transaction_request_id" => request.id,
              "correlation_id" => nil,
              "amount" => nil,
              "address" => nil,
              "metadata" => nil,
              "idempotency_token" => "4",
              "token_id" => nil
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
      assert_receive {:updated_4, _res, _response}, 5000

      consumptions = TransactionConsumption |> EWalletDB.Repo.all()
      assert length(consumptions) == 1
    end

    test "proceeds if the maximum number of consumptions hasn't been reached and
          increment it", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)
      {:ok, request} = TransactionRequest.update(meta.request, %{max_consumptions: 2})

      {res, consumption} =
        TransactionConsumptionGate.consume(meta.sender, %{
          "transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil
        })

      assert res == :ok
      assert consumption.status == "confirmed"

      {res, consumption} =
        TransactionConsumptionGate.consume(meta.sender, %{
          "transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "1234",
          "token_id" => nil
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
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {:ok, request} =
        TransactionRequest.update(meta.request, %{
          max_consumptions: 1
        })

      {res, consumption} =
        TransactionConsumptionGate.consume(meta.sender, %{
          "transaction_request_id" => request.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "address" => meta.sender_balance.address,
          "metadata" => %{},
          "idempotency_token" => "123",
          "token_id" => nil
        })

      assert res == :ok
      assert consumption.status == "confirmed"

      {res, error} =
        TransactionConsumptionGate.consume(meta.sender, %{
          "transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "1234",
          "token_id" => nil
        })

      assert res == :error
      assert error == :max_consumptions_reached
    end

    test "returns a pending request with no transfer is the request requires confirmation",
         meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {:ok, request} =
        TransactionRequest.update(meta.request, %{
          require_confirmation: true
        })

      {res, consumption} =
        TransactionConsumptionGate.consume(meta.sender, %{
          "transaction_request_id" => request.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "address" => meta.sender_balance.address,
          "metadata" => %{},
          "idempotency_token" => "123",
          "token_id" => nil
        })

      assert res == :ok
      assert consumption.status == "pending"
    end

    test "sets an expiration date for consumptions if there is a consumption lifetime provided",
         meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {:ok, request} =
        TransactionRequest.update(meta.request, %{
          require_confirmation: true,
          # 60 seconds
          consumption_lifetime: 60_000
        })

      {res, consumption} =
        TransactionConsumptionGate.consume(meta.sender, %{
          "transaction_request_id" => request.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "address" => meta.sender_balance.address,
          "metadata" => %{},
          "idempotency_token" => "123",
          "token_id" => nil
        })

      assert res == :ok
      assert consumption.status == "pending"
      assert consumption.expiration_date != nil
      assert NaiveDateTime.compare(consumption.expiration_date, NaiveDateTime.utc_now()) == :gt
    end

    test "does notset an expiration date for consumptions if the request is not require_confirmation",
         meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {:ok, request} =
        TransactionRequest.update(meta.request, %{
          # 60 seconds
          consumption_lifetime: 60_000
        })

      {res, consumption} =
        TransactionConsumptionGate.consume(meta.sender, %{
          "transaction_request_id" => request.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "address" => meta.sender_balance.address,
          "metadata" => %{},
          "idempotency_token" => "123",
          "token_id" => nil
        })

      assert res == :ok
      assert consumption.status == "confirmed"
      assert consumption.expiration_date == nil
    end

    test "overrides the amount if the request amount is overridable", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {:ok, request} =
        TransactionRequest.update(meta.request, %{
          allow_amount_override: true
        })

      {res, consumption} =
        TransactionConsumptionGate.consume(meta.sender, %{
          "transaction_request_id" => request.id,
          "correlation_id" => "123",
          "amount" => 1_123,
          "address" => meta.sender_balance.address,
          "metadata" => %{},
          "idempotency_token" => "123",
          "token_id" => nil
        })

      assert res == :ok
      assert consumption.status == "confirmed"
      assert consumption.amount == 1_123
    end

    test "returns an 'unauthorized_amount_override' error if the consumption tries to
          illegally override the amount", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {:ok, request} =
        TransactionRequest.update(meta.request, %{
          allow_amount_override: false
        })

      {res, error} =
        TransactionConsumptionGate.consume(meta.sender, %{
          "transaction_request_id" => request.id,
          "correlation_id" => "123",
          "amount" => 1_123,
          "address" => meta.sender_balance.address,
          "metadata" => %{},
          "idempotency_token" => "123",
          "token_id" => nil
        })

      assert res == :error
      assert error == :unauthorized_amount_override
    end

    test "returns an error if the minted tokens are different", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)
      different_minted_token = insert(:minted_token)

      {res, error} =
        TransactionConsumptionGate.consume(meta.sender, %{
          "transaction_request_id" => meta.request.id,
          "correlation_id" => "123",
          "amount" => 0,
          "address" => meta.sender_balance.address,
          "metadata" => %{},
          "idempotency_token" => "123",
          "token_id" => different_minted_token.id
        })

      assert res == :error
      assert error == :invalid_minted_token_provided
    end

    test "returns an error if the consumption tries to set an amount equal to 0", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, changeset} =
        TransactionConsumptionGate.consume(meta.sender, %{
          "transaction_request_id" => meta.request.id,
          "correlation_id" => "123",
          "amount" => 0,
          "address" => meta.sender_balance.address,
          "metadata" => %{},
          "idempotency_token" => "123",
          "token_id" => nil
        })

      assert res == :error

      assert changeset.errors == [
               amount: {"must be greater than %{number}", [validation: :number, number: 0]}
             ]
    end

    test "returns the same consumption when idempency_token is the same", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, consumption_1} =
        TransactionConsumptionGate.consume(meta.sender, %{
          "transaction_request_id" => meta.request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil
        })

      assert res == :ok

      {res, consumption_2} =
        TransactionConsumptionGate.consume(meta.sender, %{
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
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          minted_token_uuid: meta.minted_token.uuid,
          user_uuid: meta.receiver.uuid,
          balance: meta.receiver_balance,
          amount: nil
        )

      {error, changeset} =
        TransactionConsumptionGate.consume(meta.sender, %{
          "transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil
        })

      assert error == :error
      assert changeset.errors == [amount: {"can't be blank", [validation: :required]}]
    end

    test "returns 'balance_not_found' when address is invalid", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, error} =
        TransactionConsumptionGate.consume(meta.sender, %{
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
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)
      balance = insert(:balance)

      {res, error} =
        TransactionConsumptionGate.consume(meta.sender, %{
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
      {res, error} =
        TransactionConsumptionGate.consume(meta.sender, %{
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
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, consumption} =
        TransactionConsumptionGate.consume(meta.sender, %{
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
      assert %TransactionConsumption{} = consumption
    end

    test "returns nil when given nil" do
      assert TransactionConsumptionGate.get(nil) == {:error, :transaction_consumption_not_found}
    end

    test "returns nil when given invalid UUID" do
      assert TransactionConsumptionGate.get("123") == {:error, :transaction_consumption_not_found}
    end
  end

  describe "confirm/3 with Account" do
    test "confirms the consumption if approved as account", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          require_confirmation: true,
          minted_token_uuid: meta.minted_token.uuid,
          account_uuid: meta.account.uuid,
          amount: 100_000 * meta.minted_token.subunit_to_unit
        )

      {res, consumption} =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_balance.address
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      {:ok, consumption} = TransactionConsumptionGate.confirm(consumption.id, true, meta.account)
      assert consumption.status == "confirmed"
      assert consumption.approved_at != nil
    end

    test "confirms a user's consumption if created and approved as account", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, request} =
        TransactionRequestGate.create(%{
          "type" => "receive",
          "token_id" => meta.minted_token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "account_id" => meta.account.id,
          "provider_user_id" => meta.receiver.provider_user_id,
          "address" => meta.receiver_balance.address,
          "require_confirmation" => true
        })

      assert res == :ok

      {res, consumption} =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_balance.address
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      {:ok, consumption} = TransactionConsumptionGate.confirm(consumption.id, true, meta.account)
      assert consumption.status == "confirmed"
      assert consumption.approved_at != nil
    end

    test "fails to confirm the consumption if not owner", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          require_confirmation: true,
          minted_token_uuid: meta.minted_token.uuid,
          user_uuid: meta.sender.uuid,
          amount: 100_000 * meta.minted_token.subunit_to_unit
        )

      {res, consumption} =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_balance.address
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      res = TransactionConsumptionGate.confirm(consumption.id, true, meta.account)
      assert res == {:error, :not_transaction_request_owner}
    end

    test "fails to confirm the consumption if expired", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          require_confirmation: true,
          minted_token_uuid: meta.minted_token.uuid,
          account_uuid: meta.account.uuid,
          amount: 100_000 * meta.minted_token.subunit_to_unit
        )

      {res, consumption} =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_balance.address
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      {:ok, transaction_request} = TransactionRequest.expire(transaction_request)
      assert transaction_request.expired_at != nil

      res = TransactionConsumptionGate.confirm(consumption.id, true, meta.account)
      assert res == {:error, :expired_transaction_request}
    end

    test "rejects the consumption if not approved as account", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          require_confirmation: true,
          minted_token_uuid: meta.minted_token.uuid,
          account_uuid: meta.account.uuid,
          amount: 100_000 * meta.minted_token.subunit_to_unit
        )

      {res, consumption} =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_balance.address
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      {:ok, consumption} = TransactionConsumptionGate.confirm(consumption.id, false, meta.account)
      assert consumption.status == "rejected"
      assert consumption.approved_at == nil
    end

    test "allows only one confirmation with two confirms at the same time", meta do
      initialize_balance(meta.sender_balance, 1_000_000, meta.minted_token)

      request =
        insert(
          :transaction_request,
          type: "receive",
          require_confirmation: true,
          minted_token_uuid: meta.minted_token.uuid,
          account_uuid: meta.account.uuid,
          amount: 100_000 * meta.minted_token.subunit_to_unit,
          max_consumptions: 1
        )

      params = fn ->
        %{
          "transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => UUID.generate(),
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_balance.address
        }
      end

      max = 10
      range = Enum.into(1..max, [])

      consumptions =
        Enum.map(range, fn _i ->
          {:ok, consumption} = TransactionConsumptionGate.consume(params.())
          consumption
        end)

      Enum.each(consumptions, fn c ->
        assert c.status == "pending"
      end)

      pid = self()

      consumptions
      |> Enum.with_index()
      |> Enum.each(fn {c, i} ->
        {:ok, _new_pid} =
          Task.start_link(fn ->
            Sandbox.allow(EWalletDB.Repo, pid, self())
            Sandbox.allow(LocalLedgerDB.Repo, pid, self())

            {res, response} = TransactionConsumptionGate.confirm(c.id, true, meta.account)
            send(pid, {String.to_atom("updated_#{i + 1}"), res, response})
          end)
      end)

      Enum.each(range, fn i ->
        update = String.to_atom("updated_#{i}")
        assert_receive {^update, _res, _response}, 5000
      end)

      consumptions = TransactionConsumption |> EWalletDB.Repo.all()
      assert length(consumptions) == max
      assert Enum.count(consumptions, fn c -> c.status == "confirmed" end) == 1
      assert Enum.count(consumptions, fn c -> c.status == "pending" end) == max - 1
    end
  end

  describe "confirm/3 with User" do
    test "confirms the consumption if approved as user", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          require_confirmation: true,
          minted_token_uuid: meta.minted_token.uuid,
          user_uuid: meta.receiver.uuid,
          amount: 100_000 * meta.minted_token.subunit_to_unit
        )

      {res, consumption} =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_balance.address
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      {:ok, consumption} = TransactionConsumptionGate.confirm(consumption.id, true, meta.receiver)
      assert consumption.status == "confirmed"
      assert consumption.approved_at != nil
    end

    test "confirms a user's consumption if created and approved as user", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      {res, request} =
        TransactionRequestGate.create(%{
          "type" => "receive",
          "token_id" => meta.minted_token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "account_id" => meta.account.id,
          "provider_user_id" => meta.receiver.provider_user_id,
          "address" => meta.receiver_balance.address,
          "require_confirmation" => true
        })

      assert res == :ok

      {res, consumption} =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_balance.address
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      {:ok, consumption} = TransactionConsumptionGate.confirm(consumption.id, true, meta.receiver)
      assert consumption.status == "confirmed"
      assert consumption.approved_at != nil
    end

    test "fails to confirm the consumption if not owner", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          require_confirmation: true,
          minted_token_uuid: meta.minted_token.uuid,
          user_uuid: meta.receiver.uuid,
          amount: 100_000 * meta.minted_token.subunit_to_unit
        )

      {res, consumption} =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_balance.address
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      res = TransactionConsumptionGate.confirm(consumption.id, true, meta.sender)
      assert res == {:error, :not_transaction_request_owner}
    end

    test "fails to confirm the consumption if expired", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          require_confirmation: true,
          minted_token_uuid: meta.minted_token.uuid,
          user_uuid: meta.receiver.uuid,
          amount: 100_000 * meta.minted_token.subunit_to_unit
        )

      {res, consumption} =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_balance.address
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      {:ok, transaction_request} = TransactionRequest.expire(transaction_request)
      assert transaction_request.expired_at != nil

      res = TransactionConsumptionGate.confirm(consumption.id, true, meta.receiver)
      assert res == {:error, :expired_transaction_request}
    end

    test "rejects the consumption if not approved as account", meta do
      initialize_balance(meta.sender_balance, 200_000, meta.minted_token)

      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          require_confirmation: true,
          minted_token_uuid: meta.minted_token.uuid,
          user_uuid: meta.receiver.uuid,
          amount: 100_000 * meta.minted_token.subunit_to_unit
        )

      {res, consumption} =
        TransactionConsumptionGate.consume(%{
          "transaction_request_id" => transaction_request.id,
          "correlation_id" => nil,
          "amount" => nil,
          "metadata" => nil,
          "idempotency_token" => "123",
          "token_id" => nil,
          "user_id" => meta.sender.id,
          "address" => meta.sender_balance.address
        })

      assert res == :ok
      assert %TransactionConsumption{} = consumption
      assert consumption.status == "pending"
      assert consumption.approved_at == nil

      {:ok, consumption} =
        TransactionConsumptionGate.confirm(consumption.id, false, meta.receiver)

      assert consumption.status == "rejected"
      assert consumption.approved_at == nil
    end
  end
end
