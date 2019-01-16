# Copyright 2018 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EWallet.TransactionRequestFetcherTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.{TransactionRequestFetcher, TransactionRequestGate}
  alias EWalletDB.{Account, TransactionRequest, User}
  alias ActivityLogger.System

  setup do
    {:ok, user} = :user |> params_for() |> User.insert()
    {:ok, account} = :account |> params_for() |> Account.insert()
    token = insert(:token)
    user_wallet = User.get_primary_wallet(user)
    account_wallet = Account.get_primary_wallet(account)

    %{
      user: user,
      token: token,
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
          "token_id" => meta.token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "address" => meta.user_wallet.address,
          "originator" => %System{}
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
