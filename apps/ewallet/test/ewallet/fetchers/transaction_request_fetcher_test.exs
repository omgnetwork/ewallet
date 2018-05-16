defmodule EWallet.TransactionRequestFetcherTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.{TransactionRequestGate, TransactionRequestFetcher}
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

  describe "get/1" do
    test "returns the request do when given valid ID", meta do
      {:ok, request} =
        TransactionRequestGate.create(meta.user, %{
          "type" => "receive",
          "token_id" => meta.minted_token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "address" => meta.user_balance.address
        })

      assert {:ok, request} = TransactionRequestFetcher.get(request.id)
      assert %TransactionRequest{} = request
    end

    test "returns nil when given nil" do
      assert TransactionRequestFetcher.get(nil) == {:error, :transaction_request_not_found}
    end

    test "returns nil when given invalid UUID" do
      assert TransactionRequestFetcher.get("123") == {:error, :transaction_request_not_found}
    end
  end

  describe "get_with_lock/1" do
    test "returns the request when given a valid ID" do
      request = insert(:transaction_request)
      assert {:ok, request} = TransactionRequestFetcher.get_with_lock(request.id)
      assert %TransactionRequest{} = request
    end

    test "returns a 'transaction_request_not_found' error when given nil" do
      assert TransactionRequestFetcher.get_with_lock(nil) == {:error, :transaction_request_not_found}
    end

    test "returns a 'transaction_request_not_found' error when given invalid UUID" do
      assert TransactionRequestFetcher.get_with_lock("123") ==
               {:error, :transaction_request_not_found}
    end
  end
end
