defmodule EWallet.TransactionRequestTest do
 use EWallet.LocalLedgerCase, async: true
 alias EWallet.TransactionRequestGate
 alias EWalletDB.{User, TransactionRequest}

  setup do
    {:ok, user}     = :user |> params_for() |> User.insert()
    {:ok, account}  = :account |> params_for() |> Account.insert()
    minted_token    = insert(:minted_token)
    user_balance    = User.get_primary_balance(user)
    account_balance = Account.get_primary_balance(account)

    %{
      user: user,
      minted_token: minted_token,
      user_balance: user_balance,
      account_balance: account_balance,
      account: account
    }
  end

  describe "create/1 with account_id" do
    test "with nil account_id and no address", meta do
      res = TransactionRequestGate.create(%{
        "type" => "receive",
        "token_id" => meta.minted_token.friendly_id,
        "correlation_id" => "123",
        "amount" => 1_000,
        "account_id" => nil
      })

      assert res == {:error, :account_id_not_found}
    end

    test "with invalid account_id and no address", meta do
      res = TransactionRequestGate.create(%{
        "type" => "receive",
        "token_id" => meta.minted_token.friendly_id,
        "correlation_id" => "123",
        "amount" => 1_000,
        "account_id" => "fake"
      })

      assert res == {:error, :account_id_not_found}
    end

    test "with valid account_id and nil address", meta do
      res = TransactionRequestGate.create(%{
        "type" => "receive",
        "token_id" => meta.minted_token.friendly_id,
        "correlation_id" => "123",
        "amount" => 1_000,
        "account_id" => "fake",
        "address" => nil
      })

      assert res == {:error, :account_id_not_found}
    end

    test "with valid account_id and no address", meta do
      {res, request} = TransactionRequestGate.create(%{
        "type" => "receive",
        "token_id" => meta.minted_token.friendly_id,
        "correlation_id" => "123",
        "amount" => 1_000,
        "account_id" => meta.account.id
      })

      assert res == :ok
      assert %TransactionRequest{} = request
    end

    test "with valid account_id and a valid address", meta do
      {res, request} = TransactionRequestGate.create(%{
        "type" => "receive",
        "token_id" => meta.minted_token.friendly_id,
        "correlation_id" => "123",
        "amount" => 1_000,
        "account_id" => meta.account.id,
        "address" => meta.account_balance.address
      })

      assert res == :ok
      assert %TransactionRequest{} = request
      assert request.status == "valid"
    end

    test "with valid account_id and an invalid address", meta do
      res = TransactionRequestGate.create(%{
       "type" => "receive",
       "token_id" => meta.minted_token.friendly_id,
       "correlation_id" => "123",
       "amount" => 1_000,
       "account_id" => meta.account.id,
       "address" => "fake"
      })

      assert res == {:error, :balance_not_found}
    end

    test "with valid account_id and an address that does not belong to the account", meta do
      res = TransactionRequestGate.create(%{
       "type" => "receive",
       "token_id" => meta.minted_token.friendly_id,
       "correlation_id" => "123",
       "amount" => 1_000,
       "account_id" => meta.account.id,
       "address" => meta.user_balance.address
      })

      assert res == {:error, :account_balance_mismatch}
    end
  end

  describe "create/1 with provider_user_id" do
    test "with nil provider_user_id and no address", meta do
      res = TransactionRequestGate.create(%{
        "type" => "receive",
        "token_id" => meta.minted_token.friendly_id,
        "correlation_id" => "123",
        "amount" => 1_000,
        "provider_user_id" => nil
      })

      assert res == {:error, :provider_user_id_not_found}
    end

    test "with invalid provider_user_id and no address", meta do
      res = TransactionRequestGate.create(%{
        "type" => "receive",
        "token_id" => meta.minted_token.friendly_id,
        "correlation_id" => "123",
        "amount" => 1_000,
        "provider_user_id" => "fake"
      })

      assert res == {:error, :provider_user_id_not_found}
    end

    test "with valid provider_user_id and no address", meta do
      {res, request} = TransactionRequestGate.create(%{
        "type" => "receive",
        "token_id" => meta.minted_token.friendly_id,
        "correlation_id" => "123",
        "amount" => 1_000,
        "provider_user_id" => meta.user.provider_user_id
      })

      assert res == :ok
      assert %TransactionRequest{} = request
    end

    test "with valid provider_user_id and a valid address", meta do
      {res, request} = TransactionRequestGate.create(%{
        "type" => "receive",
        "token_id" => meta.minted_token.friendly_id,
        "correlation_id" => "123",
        "amount" => 1_000,
        "provider_user_id" => meta.user.provider_user_id,
        "address" => meta.user_balance.address
      })

      assert res == :ok
      assert %TransactionRequest{} = request
    end

    test "with valid provider_user_id and an invalid address", meta do
      res = TransactionRequestGate.create(%{
        "type" => "receive",
        "token_id" => meta.minted_token.friendly_id,
        "correlation_id" => "123",
        "amount" => 1_000,
        "provider_user_id" => meta.user.provider_user_id,
        "address" => "fake"
      })

      assert res == {:error, :balance_not_found}
    end

    test "with valid provider_user_id and an address that does not belong to the user", meta do
      res = TransactionRequestGate.create(%{
        "type" => "receive",
        "token_id" => meta.minted_token.friendly_id,
        "correlation_id" => "123",
        "amount" => 1_000,
        "provider_user_id" => meta.user.provider_user_id,
        "address" => meta.account_balance.address
      })

      assert res == {:error, :user_balance_mismatch}
    end
  end

  describe "create/1 with address" do
    test "with nil address", meta do
      res = TransactionRequestGate.create(%{
        "type" => "receive",
        "token_id" => meta.minted_token.friendly_id,
        "correlation_id" => "123",
        "amount" => 1_000,
        "address" => nil
      })

      assert res == {:error, :balance_not_found}
    end

    test "with a valid address", meta do
      {res, request} = TransactionRequestGate.create(%{
        "type" => "receive",
        "token_id" => meta.minted_token.friendly_id,
        "correlation_id" => "123",
        "amount" => 1_000,
        "address" => meta.user_balance.address
      })

      assert res == :ok
      assert %TransactionRequest{} = request
    end

    test "with an invalid address", meta do
      res = TransactionRequestGate.create(%{
        "type" => "receive",
        "token_id" => meta.minted_token.friendly_id,
        "correlation_id" => "123",
        "amount" => 1_000,
        "address" => "fake"
      })

      assert res == {:error, :balance_not_found}
    end

  end

  describe "create/1 with invalid parameters" do
    test "with invalid parameters", meta do
      res = TransactionRequestGate.create(%{
        "type" => "receive",
        "token_id" => meta.minted_token.friendly_id,
        "correlation_id" => "123",
        "amount" => 1_000,
      })

      assert res == {:error, :invalid_parameter}
    end
  end

  describe "create/2 with %User{}" do
    test "creates a transaction request with all the params", meta do
      {:ok, request} = TransactionRequestGate.create(meta.user, %{
       "type" => "receive",
       "token_id" => meta.minted_token.friendly_id,
       "correlation_id" => "123",
       "amount" => 1_000,
       "address" => meta.user_balance.address,
      })

      assert %TransactionRequest{} = request
      assert request.id != nil
      assert request.type == "receive"
      assert request.minted_token_id == meta.minted_token.id
      assert request.correlation_id == "123"
      assert request.amount == 1_000
      assert request.balance_address == meta.user_balance.address
    end

    test "creates a transaction request with only type and token_id", meta do
      {:ok, request} = TransactionRequestGate.create(meta.user, %{
       "type" => "receive",
       "token_id" => meta.minted_token.friendly_id,
       "correlation_id" => nil,
       "amount" => nil,
       "address" => nil
      })

      assert %TransactionRequest{} = request
    end

    test "receives an invalid changeset error when the type is invalid", meta do
     {:error, changeset} = TransactionRequestGate.create(meta.user, %{
       "type" => "fake",
       "token_id" => meta.minted_token.friendly_id,
       "correlation_id" => nil,
       "amount" => nil,
       "address" => nil
     })

     assert changeset.errors == [type: {"is invalid", [validation: :inclusion]}]
    end

    test "receives a 'balance_not_found' error when the address is invalid", meta do
     {:error, error} = TransactionRequestGate.create(meta.user, %{
       "type" => "receive",
       "token_id" => meta.minted_token.friendly_id,
       "correlation_id" => nil,
       "amount" => nil,
       "address" => "fake"
     })

     assert error == :balance_not_found
    end

    test "receives an 'user_balance_mismatch' error when the address does not belong to the user",
    meta do
     balance = insert(:balance)

     {:error, error} = TransactionRequestGate.create(meta.user, %{
       "type" => "receive",
       "token_id" => meta.minted_token.friendly_id,
       "correlation_id" => nil,
       "amount" => nil,
       "address" => balance.address
     })

     assert error == :user_balance_mismatch
    end

    test "receives an 'minted_token_not_found' error when the token ID is not found", meta  do
     res = TransactionRequestGate.create(meta.user, %{
       "type" => "receive",
       "token_id" => "fake",
       "correlation_id" => nil,
       "amount" => nil,
       "address" => nil
     })

     assert res == {:error, :minted_token_not_found}
    end
  end

  describe "create/2 with %Balance{}" do
    test "creates a transaction request with all the params", meta do
      {:ok, request} = TransactionRequestGate.create(meta.user_balance, %{
       "type" => "receive",
       "token_id" => meta.minted_token.friendly_id,
       "correlation_id" => "123",
       "amount" => 1_000
      })

      assert %TransactionRequest{} = request
      assert request.id != nil
      assert request.type == "receive"
      assert request.minted_token_id == meta.minted_token.id
      assert request.correlation_id == "123"
      assert request.amount == 1_000
      assert request.balance_address == meta.user_balance.address
    end

    test "creates a transaction request with only type and token_id", meta do
      {:ok, request} = TransactionRequestGate.create(meta.user_balance, %{
       "type" => "receive",
       "token_id" => meta.minted_token.friendly_id,
       "correlation_id" => nil,
       "amount" => nil
      })

      assert %TransactionRequest{} = request
    end

    test "receives an invalid changeset error when the type is invalid", meta do
     {:error, changeset} = TransactionRequestGate.create(meta.user_balance, %{
       "type" => "fake",
       "token_id" => meta.minted_token.friendly_id,
       "correlation_id" => nil,
       "amount" => nil
     })

     assert changeset.errors == [type: {"is invalid", [validation: :inclusion]}]
    end

    test "receives a 'invalid_parameter' error when the balance is nil", meta do
     {:error, error} = TransactionRequestGate.create(nil, %{
       "type" => "receive",
       "token_id" => meta.minted_token.friendly_id,
       "correlation_id" => nil,
       "amount" => nil
     })

     assert error == :invalid_parameter
    end

    test "receives an 'minted_token_not_found' error when the token ID is not found", meta  do
     res = TransactionRequestGate.create(meta.user_balance, %{
       "type" => "receive",
       "token_id" => "fake",
       "correlation_id" => nil,
       "amount" => nil
     })

     assert res == {:error, :minted_token_not_found}
    end
  end

  describe "get/1" do
    test "returns the request do when given valid ID", meta do
      {:ok, request} = TransactionRequestGate.create(meta.user, %{
        "type" => "receive",
        "token_id" => meta.minted_token.friendly_id,
        "correlation_id" => "123",
        "amount" => 1_000,
        "address" => meta.user_balance.address,
      })

      assert {:ok, request} = TransactionRequestGate.get(request.id)
      assert %TransactionRequest{} = request
    end

    test "returns nil when given nil" do
      assert TransactionRequestGate.get(nil) == {:error, :transaction_request_not_found}
    end

    test "returns nil when given invalid UUID" do
      assert TransactionRequestGate.get("123") == {:error, :transaction_request_not_found}
    end
  end
end
