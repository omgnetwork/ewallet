defmodule EWallet.TransactionRequestValidatorTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.TransactionRequestValidator
  alias EWalletDB.{User, TransactionRequest}

  setup do
    {:ok, user} = :user |> params_for() |> User.insert()
    {:ok, account} = :account |> params_for() |> Account.insert()
    minted_token = insert(:minted_token)
    user_balance = User.get_primary_balance(user)
    account_balance = Account.get_primary_balance(account)

    %{
      user: user,
      minted_token: minted_token,
      user_balance: user_balance,
      account_balance: account_balance,
      account: account
    }
  end

  describe "allow_amount_override/2" do
    test "returns {:ok, amount} when allowed" do
      request = insert(:transaction_request, allow_amount_override: true)
      {res, amount} = TransactionRequestValidator.validate_amount(request, 1_000)

      assert res == :ok
      assert amount == 1_000
    end

    test "returns {:ok, request.amount} with nil amount when override not allowed" do
      request = insert(:transaction_request, allow_amount_override: false)
      {res, amount} = TransactionRequestValidator.validate_amount(request, nil)

      assert res == :ok
      assert amount == request.amount
    end

    test "returns {:error, :unauthorized_amount_override} when not allowed" do
      request = insert(:transaction_request, allow_amount_override: false)
      {res, error} = TransactionRequestValidator.validate_amount(request, 1_000)

      assert res == :error
      assert error == :unauthorized_amount_override
    end
  end

  describe "expiration_from_lifetime/1" do
    test "returns nil if not require_confirmation" do
      request = insert(:transaction_request, require_confirmation: false)
      date = TransactionRequestValidator.expiration_from_lifetime(request)
      assert date == nil
    end

    test "returns nil if no consumption lifetime" do
      request =
        insert(:transaction_request, require_confirmation: true, consumption_lifetime: nil)

      date = TransactionRequestValidator.expiration_from_lifetime(request)
      assert date == nil
    end

    test "returns nil if consumption lifetime is equal to 0" do
      request = insert(:transaction_request, require_confirmation: true, consumption_lifetime: 0)
      date = TransactionRequestValidator.expiration_from_lifetime(request)
      assert date == nil
    end

    test "returns the expiration date based on consumption_lifetime" do
      now = NaiveDateTime.utc_now()

      request =
        insert(
          :transaction_request,
          require_confirmation: true,
          consumption_lifetime: 1_000
        )

      date = TransactionRequestValidator.expiration_from_lifetime(request)
      assert NaiveDateTime.compare(date, now) == :gt
    end
  end

  describe "expire_if_past_expiration_date/1" do
    test "does nothing if expiration date is not set" do
      request = insert(:transaction_request, expiration_date: nil)
      {res, request} = TransactionRequestValidator.expire_if_past_expiration_date(request)
      assert res == :ok
      assert %TransactionRequest{} = request
      assert TransactionRequest.valid?(request) == true
    end

    test "does nothing if expiration date is not past" do
      future_date = NaiveDateTime.add(NaiveDateTime.utc_now(), 60, :second)
      request = insert(:transaction_request, expiration_date: future_date)
      {res, request} = TransactionRequestValidator.expire_if_past_expiration_date(request)
      assert res == :ok
      assert %TransactionRequest{} = request
      assert TransactionRequest.valid?(request) == true
    end

    test "expires the request if expiration date is past" do
      past_date = NaiveDateTime.add(NaiveDateTime.utc_now(), -60, :second)
      request = insert(:transaction_request, expiration_date: past_date)
      {res, error} = TransactionRequestValidator.expire_if_past_expiration_date(request)
      request = TransactionRequest.get(request.id)
      assert res == :error
      assert error == :expired_transaction_request
      assert TransactionRequest.valid?(request) == false
      assert TransactionRequest.expired?(request) == true
    end
  end

  describe "expire_if_max_consumption/1" do
    test "touches the request if max_consumptions is equal to nil" do
      request = insert(:transaction_request, max_consumptions: nil)
      {res, updated_request} = TransactionRequestValidator.expire_if_max_consumption(request)
      assert res == :ok
      assert %TransactionRequest{} = updated_request
      assert TransactionRequest.valid?(updated_request) == true
      assert NaiveDateTime.compare(updated_request.updated_at, request.updated_at) == :gt
    end

    test "touches the request if max_consumptions is equal to 0" do
      request = insert(:transaction_request, max_consumptions: 0)
      {res, updated_request} = TransactionRequestValidator.expire_if_max_consumption(request)
      assert res == :ok
      assert %TransactionRequest{} = updated_request
      assert TransactionRequest.valid?(updated_request) == true
      assert NaiveDateTime.compare(updated_request.updated_at, request.updated_at) == :gt
    end

    test "touches the request if max_consumptions has not been reached" do
      request = insert(:transaction_request, max_consumptions: 3)
      {res, updated_request} = TransactionRequestValidator.expire_if_max_consumption(request)
      assert res == :ok
      assert %TransactionRequest{} = updated_request
      assert TransactionRequest.valid?(updated_request) == true
      assert NaiveDateTime.compare(updated_request.updated_at, request.updated_at) == :gt
    end

    test "expires the request if max_consumptions has been reached" do
      request = insert(:transaction_request, max_consumptions: 2)

      _consumption =
        insert(
          :transaction_consumption,
          transaction_request_uuid: request.uuid,
          status: "confirmed"
        )

      _consumption =
        insert(
          :transaction_consumption,
          transaction_request_uuid: request.uuid,
          status: "confirmed"
        )

      {res, updated_request} = TransactionRequestValidator.expire_if_max_consumption(request)
      assert res == :ok
      assert %TransactionRequest{} = updated_request
      assert updated_request.expired_at != nil
      assert updated_request.expiration_reason == "max_consumptions_reached"
      assert TransactionRequest.valid?(updated_request) == false
      assert TransactionRequest.expired?(updated_request) == true
    end
  end

  describe "valid?/1" do
    test "returns {:ok, request} if valid" do
      request = insert(:transaction_request)
      assert TransactionRequestValidator.validate_request(request) == {:ok, request}
    end

    test "returns {:error, expiration_reason} if expired" do
      request = insert(:transaction_request, status: "expired", expiration_reason: "something")
      assert TransactionRequestValidator.validate_request(request) == {:error, :something}
    end
  end
end
