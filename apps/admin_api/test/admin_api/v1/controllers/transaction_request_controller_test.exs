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

defmodule AdminAPI.V1.TransactionRequestControllerTest do
  use AdminAPI.ConnCase, async: true
  alias Utils.Helpers.DateFormatter
  alias EWallet.Web.V1.{AccountSerializer, TokenSerializer, UserSerializer, WalletSerializer}
  alias EWalletDB.{Account, AccountUser, Repo, TransactionRequest, User, Wallet}
  alias ActivityLogger.System

  describe "/transaction_request.all" do
    setup do
      user = get_test_user()
      account = Account.get_master_account()
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

      tr_1 = insert(:transaction_request, user_uuid: user.uuid, status: "valid")
      tr_2 = insert(:transaction_request, account_uuid: account.uuid, status: "valid")
      tr_3 = insert(:transaction_request, account_uuid: account.uuid, status: "expired")

      %{
        user: user,
        tr_1: tr_1,
        tr_2: tr_2,
        tr_3: tr_3
      }
    end

    test_with_auths "returns all the transaction_requests", context do
      response =
        request("/transaction_request.all", %{
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      transfers = [
        context.tr_1,
        context.tr_2,
        context.tr_3
      ]

      assert length(response["data"]["data"]) == length(transfers)

      # All transfers made during setup should exist in the response
      assert Enum.all?(transfers, fn transfer ->
               Enum.any?(response["data"]["data"], fn data ->
                 transfer.id == data["id"]
               end)
             end)
    end

    test_with_auths "returns all the transaction_requests for a specific status", context do
      response =
        request("/transaction_request.all", %{
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "search_terms" => %{
            "status" => "valid"
          }
        })

      assert response["data"]["data"] |> length() == 2

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               context.tr_1.id,
               context.tr_2.id
             ]
    end

    test_with_auths "returns all transaction_requests filtered", context do
      response =
        request("/transaction_request.all", %{
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "search_term" => "valid"
        })

      assert response["data"]["data"] |> length() == 2

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               context.tr_1.id,
               context.tr_2.id
             ]
    end

    test_with_auths "returns all transaction_requests sorted and paginated", context do
      response =
        request("/transaction_request.all", %{
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "per_page" => 2,
          "page" => 1
        })

      assert response["data"]["data"] |> length() == 2
      transaction_1 = Enum.at(response["data"]["data"], 0)
      transaction_2 = Enum.at(response["data"]["data"], 1)
      assert transaction_2["created_at"] > transaction_1["created_at"]

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               context.tr_1.id,
               context.tr_2.id
             ]
    end

    # The endpoint will scope the result to the consumptions associated with the requester,
    # hence the customized factory attrs to make sure the results will be found.
    test_supports_match_any(
      "/transaction_request.all",
      :transaction_request,
      :correlation_id,
      factory_attrs: %{
        user_uuid: get_test_admin().uuid,
        account_uuid: Account.get_master_account().uuid
      }
    )

    # The endpoint will scope the result to the consumptions associated with the requester,
    # hence the customized factory attrs to make sure the results will be found.
    test_supports_match_all(
      "/transaction_request.all",
      :transaction_request,
      :correlation_id,
      factory_attrs: %{
        user_uuid: get_test_admin().uuid,
        account_uuid: Account.get_master_account().uuid
      }
    )
  end

  describe "/transaction_request.create" do
    test_with_auths "creates a transaction request with all the params and exchange wallet" do
      account = Account.get_master_account()
      user = get_test_user()
      token = insert(:token)
      account_wallet = Account.get_primary_wallet(account)
      wallet = User.get_primary_wallet(user)
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

      response =
        request("/transaction_request.create", %{
          type: "send",
          token_id: token.id,
          correlation_id: "123",
          amount: 1_000,
          address: wallet.address,
          exchange_wallet_address: account_wallet.address
        })

      request = TransactionRequest |> Repo.all() |> Enum.at(0)

      assert response == %{
               "success" => true,
               "version" => "1",
               "data" => %{
                 "object" => "transaction_request",
                 "amount" => 1_000,
                 "address" => wallet.address,
                 "correlation_id" => "123",
                 "id" => request.id,
                 "formatted_id" => request.id,
                 "socket_topic" => "transaction_request:#{request.id}",
                 "token_id" => token.id,
                 "token" => token |> TokenSerializer.serialize() |> stringify_keys(),
                 "type" => "send",
                 "status" => "valid",
                 "user_id" => user.id,
                 "user" => user |> UserSerializer.serialize() |> stringify_keys(),
                 "account_id" => nil,
                 "account" => nil,
                 "allow_amount_override" => true,
                 "require_confirmation" => false,
                 "consumption_lifetime" => nil,
                 "encrypted_metadata" => %{},
                 "expiration_date" => nil,
                 "expiration_reason" => nil,
                 "expired_at" => nil,
                 "max_consumptions" => nil,
                 "current_consumptions_count" => 0,
                 "max_consumptions_per_user" => nil,
                 "metadata" => %{},
                 "exchange_account_id" => account.id,
                 "exchange_account" =>
                   account |> AccountSerializer.serialize() |> stringify_keys(),
                 "exchange_wallet_address" => account_wallet.address,
                 "exchange_wallet" =>
                   account_wallet
                   |> WalletSerializer.serialize_without_balances()
                   |> stringify_keys(),
                 "created_at" => DateFormatter.to_iso8601(request.inserted_at),
                 "updated_at" => DateFormatter.to_iso8601(request.updated_at)
               }
             }
    end

    test_with_auths "creates a transaction request with all the params and exchange account" do
      account = Account.get_master_account()
      user = get_test_user()
      token = insert(:token)
      account_wallet = Account.get_primary_wallet(account)
      wallet = User.get_primary_wallet(user)
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

      response =
        request("/transaction_request.create", %{
          type: "send",
          token_id: token.id,
          correlation_id: "123",
          amount: 1_000,
          address: wallet.address,
          exchange_account_id: account.id
        })

      request = TransactionRequest |> Repo.all() |> Enum.at(0)

      assert response == %{
               "success" => true,
               "version" => "1",
               "data" => %{
                 "object" => "transaction_request",
                 "amount" => 1_000,
                 "address" => wallet.address,
                 "correlation_id" => "123",
                 "id" => request.id,
                 "formatted_id" => request.id,
                 "socket_topic" => "transaction_request:#{request.id}",
                 "token_id" => token.id,
                 "token" => token |> TokenSerializer.serialize() |> stringify_keys(),
                 "type" => "send",
                 "status" => "valid",
                 "user_id" => user.id,
                 "user" => user |> UserSerializer.serialize() |> stringify_keys(),
                 "account_id" => nil,
                 "account" => nil,
                 "allow_amount_override" => true,
                 "require_confirmation" => false,
                 "consumption_lifetime" => nil,
                 "encrypted_metadata" => %{},
                 "expiration_date" => nil,
                 "expiration_reason" => nil,
                 "expired_at" => nil,
                 "max_consumptions" => nil,
                 "current_consumptions_count" => 0,
                 "max_consumptions_per_user" => nil,
                 "metadata" => %{},
                 "exchange_account_id" => account.id,
                 "exchange_account" =>
                   account |> AccountSerializer.serialize() |> stringify_keys(),
                 "exchange_wallet_address" => account_wallet.address,
                 "exchange_wallet" =>
                   account_wallet
                   |> WalletSerializer.serialize_without_balances()
                   |> stringify_keys(),
                 "created_at" => DateFormatter.to_iso8601(request.inserted_at),
                 "updated_at" => DateFormatter.to_iso8601(request.updated_at)
               }
             }
    end

    test_with_auths "creates a transaction request with the minimum params" do
      account = Account.get_master_account()
      user = get_test_user()
      token = insert(:token)
      wallet = User.get_primary_wallet(user)
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

      response =
        request("/transaction_request.create", %{
          type: "send",
          token_id: token.id,
          correlation_id: nil,
          amount: nil,
          address: wallet.address
        })

      request = TransactionRequest |> Repo.all() |> Enum.at(0)

      assert response == %{
               "success" => true,
               "version" => "1",
               "data" => %{
                 "object" => "transaction_request",
                 "amount" => nil,
                 "address" => wallet.address,
                 "correlation_id" => nil,
                 "id" => request.id,
                 "formatted_id" => request.id,
                 "socket_topic" => "transaction_request:#{request.id}",
                 "token_id" => token.id,
                 "token" => token |> TokenSerializer.serialize() |> stringify_keys(),
                 "type" => "send",
                 "status" => "valid",
                 "user_id" => user.id,
                 "user" => user |> UserSerializer.serialize() |> stringify_keys(),
                 "account_id" => nil,
                 "account" => nil,
                 "exchange_account" => nil,
                 "exchange_account_id" => nil,
                 "exchange_wallet" => nil,
                 "exchange_wallet_address" => nil,
                 "allow_amount_override" => true,
                 "require_confirmation" => false,
                 "consumption_lifetime" => nil,
                 "metadata" => %{},
                 "encrypted_metadata" => %{},
                 "expiration_date" => nil,
                 "expiration_reason" => nil,
                 "expired_at" => nil,
                 "max_consumptions" => nil,
                 "current_consumptions_count" => 0,
                 "max_consumptions_per_user" => nil,
                 "created_at" => DateFormatter.to_iso8601(request.inserted_at),
                 "updated_at" => DateFormatter.to_iso8601(request.updated_at)
               }
             }
    end

    test_with_auths "creates a transaction request with string amount" do
      account = Account.get_master_account()
      user = get_test_user()
      token = insert(:token)
      wallet = User.get_primary_wallet(user)
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

      response =
        request("/transaction_request.create", %{
          type: "send",
          token_id: token.id,
          correlation_id: nil,
          amount: "1000",
          address: wallet.address
        })

      request = TransactionRequest |> Repo.all() |> Enum.at(0)

      assert response == %{
               "success" => true,
               "version" => "1",
               "data" => %{
                 "object" => "transaction_request",
                 "amount" => 1000,
                 "address" => wallet.address,
                 "correlation_id" => nil,
                 "id" => request.id,
                 "formatted_id" => request.id,
                 "socket_topic" => "transaction_request:#{request.id}",
                 "token_id" => token.id,
                 "token" => token |> TokenSerializer.serialize() |> stringify_keys(),
                 "type" => "send",
                 "status" => "valid",
                 "user_id" => user.id,
                 "user" => user |> UserSerializer.serialize() |> stringify_keys(),
                 "account_id" => nil,
                 "account" => nil,
                 "exchange_account" => nil,
                 "exchange_account_id" => nil,
                 "exchange_wallet" => nil,
                 "exchange_wallet_address" => nil,
                 "allow_amount_override" => true,
                 "require_confirmation" => false,
                 "consumption_lifetime" => nil,
                 "metadata" => %{},
                 "encrypted_metadata" => %{},
                 "expiration_date" => nil,
                 "expiration_reason" => nil,
                 "expired_at" => nil,
                 "max_consumptions" => nil,
                 "current_consumptions_count" => 0,
                 "max_consumptions_per_user" => nil,
                 "created_at" => DateFormatter.to_iso8601(request.inserted_at),
                 "updated_at" => DateFormatter.to_iso8601(request.updated_at)
               }
             }
    end

    test_with_auths "receives an error when the type is invalid" do
      account = Account.get_master_account()
      user = get_test_user()
      token = insert(:token)
      wallet = User.get_primary_wallet(user)
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

      response =
        request("/transaction_request.create", %{
          type: "fake",
          token_id: token.id,
          correlation_id: nil,
          amount: nil,
          address: wallet.address
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "client:invalid_parameter",
                 "description" => "Invalid parameter provided. `type` is invalid.",
                 "messages" => %{"type" => ["inclusion"]},
                 "object" => "error"
               }
             }
    end

    test_with_auths "receives an error when the address is invalid" do
      token = insert(:token)

      response =
        request("/transaction_request.create", %{
          type: "send",
          token_id: token.id,
          correlation_id: nil,
          amount: nil,
          address: "FAKE-0000-0000-0000"
        })

      assert response["success"] == false
      assert response["data"]["code"] == "wallet:wallet_not_found"
    end

    test_with_auths "receives an error when the address does not belong to the user" do
      account = Account.get_master_account()
      token = insert(:token)
      wallet = insert(:wallet)

      response =
        request("/transaction_request.create", %{
          type: "send",
          token_id: token.id,
          correlation_id: nil,
          amount: nil,
          account_id: account.id,
          address: wallet.address
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "account:account_wallet_mismatch",
                 "description" => "The provided wallet does not belong to the given account.",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test_with_auths "receives an error when the token ID is not found" do
      wallet = insert(:wallet)

      response =
        request("/transaction_request.create", %{
          type: "send",
          token_id: "123",
          correlation_id: nil,
          amount: nil,
          address: wallet.address
        })

      assert response["success"] == false
      assert response["data"]["code"] == "unauthorized"
    end

    test_with_auths "receives an error when the token is disabled" do
      account = Account.get_master_account()
      user = get_test_user()
      token = insert(:token, enabled: false)
      wallet = User.get_primary_wallet(user)
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

      response =
        request("/transaction_request.create", %{
          type: "send",
          token_id: token.id,
          correlation_id: nil,
          amount: nil,
          address: wallet.address
        })

      assert response["success"] == false
      assert response["data"]["code"] == "token:disabled"
    end

    test_with_auths "receives an error when the wallet is disabled" do
      account = Account.get_master_account()
      user = get_test_user()
      token = insert(:token, enabled: false)
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

      {:ok, wallet} =
        Wallet.insert_secondary_or_burn(%{
          "account_uuid" => account.uuid,
          "name" => "MySecondary",
          "identifier" => "secondary",
          "originator" => %System{}
        })

      {:ok, wallet} = Wallet.enable_or_disable(wallet, %{enabled: false, originator: %System{}})

      response =
        request("/transaction_request.create", %{
          type: "send",
          token_id: token.id,
          correlation_id: nil,
          amount: nil,
          address: wallet.address
        })

      assert response["success"] == false
      assert response["data"]["code"] == "wallet:disabled"
    end

    defp assert_create_logs(logs, originator, target) do
      assert Enum.count(logs) == 2

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: originator,
        target: target,
        changes: %{
          "amount" => target.amount,
          "correlation_id" => target.correlation_id,
          "exchange_account_uuid" => target.exchange_account.uuid,
          "exchange_wallet_address" => target.exchange_wallet.address,
          "token_uuid" => target.token.uuid,
          "type" => target.type,
          "user_uuid" => target.user.uuid,
          "wallet_address" => target.wallet.address
        },
        encrypted_changes: %{}
      )

      logs
      |> Enum.at(1)
      |> assert_activity_log(
        action: "update",
        originator: :system,
        target: target,
        changes: %{"consumptions_count" => 0},
        encrypted_changes: %{}
      )
    end
  end

  test "generates an activity log for an admin request" do
    account = Account.get_master_account()
    user = get_test_user()
    token = insert(:token)
    account_wallet = Account.get_primary_wallet(account)
    wallet = User.get_primary_wallet(user)
    {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

    timestamp = DateTime.utc_now()

    response =
      admin_user_request("/transaction_request.create", %{
        type: "send",
        token_id: token.id,
        correlation_id: "123",
        amount: 1_000,
        address: wallet.address,
        exchange_wallet_address: account_wallet.address
      })

    assert response["success"] == true

    transaction_request =
      response["data"]["id"]
      |> TransactionRequest.get()
      |> Repo.preload([:exchange_account, :exchange_wallet, :token, :user, :wallet])

    timestamp
    |> get_all_activity_logs_since()
    |> assert_create_logs(get_test_admin(), transaction_request)
  end

  test "generates an activity log for a provider request" do
    account = Account.get_master_account()
    user = get_test_user()
    token = insert(:token)
    account_wallet = Account.get_primary_wallet(account)
    wallet = User.get_primary_wallet(user)
    {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

    timestamp = DateTime.utc_now()

    response =
      provider_request("/transaction_request.create", %{
        type: "send",
        token_id: token.id,
        correlation_id: "123",
        amount: 1_000,
        address: wallet.address,
        exchange_wallet_address: account_wallet.address
      })

    assert response["success"] == true

    transaction_request =
      response["data"]["id"]
      |> TransactionRequest.get()
      |> Repo.preload([:exchange_account, :exchange_wallet, :token, :user, :wallet])

    timestamp
    |> get_all_activity_logs_since()
    |> assert_create_logs(get_test_key(), transaction_request)
  end

  describe "/transaction_request.get" do
    test_with_auths "returns the transaction request" do
      transaction_request = insert(:transaction_request)

      response =
        request("/transaction_request.get", %{
          formatted_id: transaction_request.id
        })

      assert response["success"] == true
      assert response["data"]["id"] == transaction_request.id
    end

    test_with_auths "returns :invalid_parameter error when formatted_id is not given" do
      response = request("/transaction_request.get", %{})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `formatted_id` is required."
    end

    test_with_auths "returns an error when the request ID is not found" do
      response =
        request("/transaction_request.get", %{
          formatted_id: "123"
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "unauthorized",
                 "description" => "You are not allowed to perform the requested operation.",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end
  end
end
