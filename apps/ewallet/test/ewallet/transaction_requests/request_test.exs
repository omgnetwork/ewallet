defmodule EWallet.TransactionRequests.RequestTest do
 use EWallet.LocalLedgerCase, async: true
 alias EWallet.TransactionRequests.Request
 alias EWalletDB.{User, TransactionRequest}

  setup do
    {:ok, user}  = :user |> params_for() |> User.insert()
    minted_token = insert(:minted_token)
    balance      = User.get_primary_balance(user)

    %{user: user, minted_token: minted_token, balance: balance}
  end

  describe "create/2" do
    test "creates a transaction request with all the params", meta do
      {:ok, request} = Request.create(meta.user, %{
       "type" => "receive",
       "token_id" => meta.minted_token.friendly_id,
       "correlation_id" => "123",
       "amount" => 1_000,
       "address" => meta.balance.address,
      })

      assert %TransactionRequest{} = request
      assert request.id != nil
      assert request.type == "receive"
      assert request.minted_token_id == meta.minted_token.id
      assert request.correlation_id == "123"
      assert request.amount == 1_000
      assert request.balance_address == meta.balance.address
    end

    test "creates a transaction request with only type and token_id", meta do
      {:ok, request} = Request.create(meta.user, %{
       "type" => "receive",
       "token_id" => meta.minted_token.friendly_id,
       "correlation_id" => nil,
       "amount" => nil,
       "address" => nil
      })

      assert %TransactionRequest{} = request
    end

    test "receives an invalid changeset error when the type is invalid", meta do
     {:error, changeset} = Request.create(meta.user, %{
       "type" => "fake",
       "token_id" => meta.minted_token.friendly_id,
       "correlation_id" => nil,
       "amount" => nil,
       "address" => nil
     })

     assert changeset.errors == [type: {"is invalid", [validation: :inclusion]}]
    end

    test "receives a 'balance_not_found' error when the address is invalid", meta do
     {:error, error} = Request.create(meta.user, %{
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

     {:error, error} = Request.create(meta.user, %{
       "type" => "receive",
       "token_id" => meta.minted_token.friendly_id,
       "correlation_id" => nil,
       "amount" => nil,
       "address" => balance.address
     })

     assert error == :user_balance_mismatch
    end

    test "receives an 'invalid_parameter' error when the token ID is not found", meta  do
     res = Request.create(meta.user, %{
       "type" => "receive",
       "token_id" => "fake",
       "correlation_id" => nil,
       "amount" => nil,
       "address" => nil
     })

     assert res == {:error, :minted_token_not_found}
    end
  end

  describe "get/1" do
    test "returns the request do when given valid ID", meta do
      {:ok, request} = Request.create(meta.user, %{
        "type" => "receive",
        "token_id" => meta.minted_token.friendly_id,
        "correlation_id" => "123",
        "amount" => 1_000,
        "address" => meta.balance.address,
      })

      assert {:ok, request} = Request.get(request.id)
      assert %TransactionRequest{} = request
    end

    test "returns nil when given nil" do
      assert Request.get(nil) == {:error, :transaction_request_not_found}
    end

    test "returns nil when given invalid UUID" do
      assert Request.get("123") == {:error, :transaction_request_not_found}
    end
  end
end
