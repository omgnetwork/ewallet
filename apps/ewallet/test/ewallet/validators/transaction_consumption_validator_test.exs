defmodule EWallet.TransactionConsumptionValidatorTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.{TestEndpoint, TransactionConsumptionValidator}
  alias EWalletDB.{Repo, User, Account, TransactionRequest, TransactionConsumption}

  describe "validate_before_consumption/3" do
    test "expires a transaction request if past expiration date" do
      now = NaiveDateTime.utc_now()

      request =
        insert(:transaction_request, expiration_date: NaiveDateTime.add(now, -60, :seconds))

      balance = request.balance

      {:error, error} =
        TransactionConsumptionValidator.validate_before_consumption(request, balance, %{})

      assert error == :expired_transaction_request
    end

    test "returns expiration reason if transaction request has expired" do
      {:ok, request} = :transaction_request |> insert() |> TransactionRequest.expire()
      balance = request.balance

      {:error, error} =
        TransactionConsumptionValidator.validate_before_consumption(request, balance, %{})

      assert error == :expired_transaction_request
    end

    test "returns unauthorized_amount_override amount when attempting to override illegally" do
      request = insert(:transaction_request, allow_amount_override: false)
      balance = request.balance

      {:error, error} =
        TransactionConsumptionValidator.validate_before_consumption(request, balance, %{
          "amount" => 100
        })

      assert error == :unauthorized_amount_override
    end

    test "returns the request, token and amount" do
      request = insert(:transaction_request)
      balance = request.balance

      {:ok, request, token, amount} =
        TransactionConsumptionValidator.validate_before_consumption(request, balance, %{})

      assert request.status == "valid"
      assert token.uuid == request.minted_token_uuid
      assert amount == request.amount
    end
  end

  describe "validate_before_confirmation/2" do
    test "returns not_transaction_request_owner if the request is not owned by user" do
      {:ok, user} = :user |> params_for() |> User.insert()
      consumption = :transaction_consumption |> insert() |> Repo.preload([:transaction_request])

      {status, res} =
        TransactionConsumptionValidator.validate_before_confirmation(consumption, user)

      assert status == :error
      assert res == :not_transaction_request_owner
    end

    test "returns not_transaction_request_owner if the request is not owned by account" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      consumption = :transaction_consumption |> insert() |> Repo.preload([:transaction_request])

      {status, res} =
        TransactionConsumptionValidator.validate_before_confirmation(consumption, account)

      assert status == :error
      assert res == :not_transaction_request_owner
    end

    test "expires request if past expiration date" do
      now = NaiveDateTime.utc_now()
      {:ok, user} = :user |> params_for() |> User.insert()

      request =
        insert(
          :transaction_request,
          expiration_date: NaiveDateTime.add(now, -60, :seconds),
          account_uuid: nil,
          user_uuid: user.uuid
        )

      consumption =
        :transaction_consumption
        |> insert(transaction_request_uuid: request.uuid)
        |> Repo.preload([:transaction_request])

      {status, res} =
        TransactionConsumptionValidator.validate_before_confirmation(consumption, user)

      assert status == :error
      assert res == :expired_transaction_request
    end

    test "returns expiration reason if expired request" do
      {:ok, user} = :user |> params_for() |> User.insert()

      request =
        insert(
          :transaction_request,
          status: "expired",
          expiration_reason: "max_consumptions_reached",
          account_uuid: nil,
          user_uuid: user.uuid
        )

      consumption =
        :transaction_consumption
        |> insert(transaction_request_uuid: request.uuid)
        |> Repo.preload([:transaction_request])

      {status, res} =
        TransactionConsumptionValidator.validate_before_confirmation(consumption, user)

      assert status == :error
      assert res == :max_consumptions_reached
    end

    test "returns max_consumptions_per_user_reached if the max has been reached" do
      {:ok, _} = TestEndpoint.start_link()

      {:ok, user_1} = :user |> params_for() |> User.insert()
      {:ok, user_2} = :user |> params_for() |> User.insert()
      balance = User.get_primary_balance(user_2)

      request =
        insert(
          :transaction_request,
          max_consumptions_per_user: 1,
          account_uuid: nil,
          user_uuid: user_1.uuid
        )

      _consumption =
        :transaction_consumption
        |> insert(
          account_uuid: nil,
          user_uuid: user_2.uuid,
          balance_address: balance.address,
          transaction_request_uuid: request.uuid,
          status: "confirmed"
        )

      consumption =
        :transaction_consumption
        |> insert(
          account_uuid: nil,
          balance_address: balance.address,
          user_uuid: user_2.uuid,
          transaction_request_uuid: request.uuid
        )
        |> Repo.preload([:transaction_request, :balance])

      {status, res} =
        TransactionConsumptionValidator.validate_before_confirmation(consumption, user_1)

      assert status == :error
      assert res == :max_consumptions_per_user_reached
    end

    test "expires consumption if past expiration" do
      {:ok, _} = TestEndpoint.start_link()

      now = NaiveDateTime.utc_now()
      {:ok, user} = :user |> params_for() |> User.insert()
      request = insert(:transaction_request, account_uuid: nil, user_uuid: user.uuid)

      consumption =
        :transaction_consumption
        |> insert(
          expiration_date: NaiveDateTime.add(now, -60, :seconds),
          transaction_request_uuid: request.uuid
        )
        |> Repo.preload([:transaction_request])

      {status, res} =
        TransactionConsumptionValidator.validate_before_confirmation(consumption, user)

      assert status == :error
      assert res == :expired_transaction_consumption
    end

    test "returns expired_transaction_consumption if the consumption has expired" do
      {:ok, _} = TestEndpoint.start_link()

      {:ok, user} = :user |> params_for() |> User.insert()
      request = insert(:transaction_request, account_uuid: nil, user_uuid: user.uuid)

      consumption =
        :transaction_consumption
        |> insert(status: "expired", transaction_request_uuid: request.uuid)
        |> Repo.preload([:transaction_request])

      {status, res} =
        TransactionConsumptionValidator.validate_before_confirmation(consumption, user)

      assert status == :error
      assert res == :expired_transaction_consumption
    end

    test "returns the consumption if valid" do
      {:ok, _} = TestEndpoint.start_link()

      {:ok, user} = :user |> params_for() |> User.insert()
      request = insert(:transaction_request, account_uuid: nil, user_uuid: user.uuid)

      consumption =
        :transaction_consumption
        |> insert(transaction_request_uuid: request.uuid)
        |> Repo.preload([:transaction_request])

      {status, res} =
        TransactionConsumptionValidator.validate_before_confirmation(consumption, user)

      assert status == :ok
      assert %TransactionConsumption{} = res
      assert res.status == "pending"
    end
  end

  describe "get_and_validate_minted_token/2" do
    test "returns the request's minted token if nil is passed" do
      request = insert(:transaction_request)

      {:ok, token} = TransactionConsumptionValidator.get_and_validate_minted_token(request, nil)
      assert token.uuid == request.minted_token_uuid
    end

    test "returns a minted_token_not_found error if given not existing token" do
      request = insert(:transaction_request)

      {:error, code} =
        TransactionConsumptionValidator.get_and_validate_minted_token(request, "fake")

      assert code == :minted_token_not_found
    end

    test "returns a invalid_minted_token_provided error if given a different minted token" do
      request = insert(:transaction_request)
      token = insert(:minted_token)

      {:error, code} =
        TransactionConsumptionValidator.get_and_validate_minted_token(request, token.id)

      assert code == :invalid_minted_token_provided
    end

    test "returns the specified minted token if valid" do
      request = :transaction_request |> insert() |> Repo.preload([:minted_token])
      token = request.minted_token

      {:ok, token} =
        TransactionConsumptionValidator.get_and_validate_minted_token(request, token.id)

      assert token.uuid == request.minted_token_uuid
    end
  end

  describe "validate_max_consumptions_per_user/2" do
    test "returns the balance if max_consumptions_per_user is not set" do
      request = insert(:transaction_request)
      balance = insert(:balance)

      {status, res} =
        TransactionConsumptionValidator.validate_max_consumptions_per_user(request, balance)

      assert status == :ok
      assert res == balance
    end

    test "returns the balance if the request is for an account" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      balance = Account.get_primary_balance(account)
      request = insert(:transaction_request, max_consumptions_per_user: 0)

      {status, res} =
        TransactionConsumptionValidator.validate_max_consumptions_per_user(request, balance)

      assert status == :ok
      assert res == balance
    end

    test "returns the balance if the current number of active consumptions is lower
          than the max_consumptions_per_user" do
      {:ok, user} = :user |> params_for() |> User.insert()
      balance = User.get_primary_balance(user)
      request = insert(:transaction_request, max_consumptions_per_user: 1)

      {status, res} =
        TransactionConsumptionValidator.validate_max_consumptions_per_user(request, balance)

      assert status == :ok
      assert res == balance
    end

    test "returns max_consumptions_per_user_reached when it has been reached" do
      {:ok, user} = :user |> params_for() |> User.insert()
      balance = User.get_primary_balance(user)
      request = insert(:transaction_request, max_consumptions_per_user: 0)

      {status, res} =
        TransactionConsumptionValidator.validate_max_consumptions_per_user(request, balance)

      assert status == :error
      assert res == :max_consumptions_per_user_reached
    end
  end
end
