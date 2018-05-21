defmodule EWallet.TransactionRequestFetcherTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.{TransactionRequestGate, TransactionRequestFetcher}
  alias EWalletDB.{User, TransactionRequest}

  # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
  setup do
    {:ok, user} = :user |> params_for() |> User.insert()
    {:ok, account} = :account |> params_for() |> Account.insert()
    minted_token = insert(:minted_token)
    user_wallet = User.get_primary_wallet(user)
    account_wallet = Account.get_primary_wallet(account)

    %{
      user: user,
      minted_token: minted_token,
      user_wallet: user_wallet,
      account_wallet: account_wallet,
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
          "address" => meta.user_wallet.address
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
      assert TransactionRequestFetcher.get_with_lock(nil) ==
               {:error, :transaction_request_not_found}
    end

    test "returns a 'transaction_request_not_found' error when given invalid UUID" do
      assert TransactionRequestFetcher.get_with_lock("123") ==
               {:error, :transaction_request_not_found}
    end
  end
end
