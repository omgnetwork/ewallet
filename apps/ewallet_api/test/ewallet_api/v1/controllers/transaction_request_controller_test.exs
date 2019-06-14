# Copyright 2018-2019 OmiseGO Pte Ltd
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

defmodule EWalletAPI.V1.TransactionRequestControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias EWallet.Web.V1.{TokenSerializer, UserSerializer}
  alias EWalletDB.{Repo, TransactionRequest, User}
  alias Utils.Helpers.DateFormatter

  describe "/me.create_transaction_request" do
    test "creates a transaction request with all the params" do
      user = get_test_user()
      token = insert(:token)
      wallet = User.get_primary_wallet(user)

      response =
        client_request("/me.create_transaction_request", %{
          type: "send",
          token_id: token.id,
          correlation_id: "123",
          amount: 1_000,
          address: wallet.address,
          max_consumptions: 3,
          max_consumptions_per_user: 1
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
                 "max_consumptions" => 3,
                 "max_consumptions_per_user" => 1,
                 "max_consumptions_per_interval" => nil,
                 "max_consumptions_per_interval_per_user" => nil,
                 "consumption_interval_duration" => nil,
                 "current_consumptions_count" => 0,
                 "created_at" => DateFormatter.to_iso8601(request.inserted_at),
                 "updated_at" => DateFormatter.to_iso8601(request.updated_at)
               }
             }
    end

    test "creates a transaction request with the minimum params" do
      user = get_test_user()
      token = insert(:token)
      wallet = User.get_primary_wallet(user)

      response =
        client_request("/me.create_transaction_request", %{
          type: "send",
          token_id: token.id
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
                 "allow_amount_override" => true,
                 "require_confirmation" => false,
                 "consumption_lifetime" => nil,
                 "metadata" => %{},
                 "encrypted_metadata" => %{},
                 "expiration_date" => nil,
                 "expiration_reason" => nil,
                 "expired_at" => nil,
                 "max_consumptions" => nil,
                 "max_consumptions_per_user" => nil,
                 "max_consumptions_per_interval" => nil,
                 "max_consumptions_per_interval_per_user" => nil,
                 "consumption_interval_duration" => nil,
                 "current_consumptions_count" => 0,
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
                 "created_at" => DateFormatter.to_iso8601(request.inserted_at),
                 "updated_at" => DateFormatter.to_iso8601(request.updated_at)
               }
             }
    end

    test "creates a transaction request with nil address" do
      user = get_test_user()
      token = insert(:token)
      wallet = User.get_primary_wallet(user)

      response =
        client_request("/me.create_transaction_request", %{
          type: "send",
          token_id: token.id,
          address: nil
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
                 "allow_amount_override" => true,
                 "require_confirmation" => false,
                 "consumption_lifetime" => nil,
                 "metadata" => %{},
                 "encrypted_metadata" => %{},
                 "expiration_date" => nil,
                 "expiration_reason" => nil,
                 "expired_at" => nil,
                 "max_consumptions" => nil,
                 "max_consumptions_per_user" => nil,
                 "max_consumptions_per_interval" => nil,
                 "max_consumptions_per_interval_per_user" => nil,
                 "consumption_interval_duration" => nil,
                 "current_consumptions_count" => 0,
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
                 "created_at" => DateFormatter.to_iso8601(request.inserted_at),
                 "updated_at" => DateFormatter.to_iso8601(request.updated_at)
               }
             }
    end

    test "receives an error when the type is invalid" do
      token = insert(:token)

      response =
        client_request("/me.create_transaction_request", %{
          type: "fake",
          token_id: token.id,
          correlation_id: nil,
          amount: nil,
          address: nil
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

    test "receives an 'unauthorized' error when the address is invalid" do
      token = insert(:token)

      response =
        client_request("/me.create_transaction_request", %{
          type: "send",
          token_id: token.id,
          correlation_id: nil,
          amount: nil,
          address: "fake000000000000"
        })

      refute response["success"]
      assert response["data"]["code"] == "unauthorized"
    end

    test "receives an 'unauthorized' error when the address does not belong to the user" do
      token = insert(:token)
      wallet = insert(:wallet)

      response =
        client_request("/me.create_transaction_request", %{
          type: "send",
          token_id: token.id,
          correlation_id: nil,
          amount: nil,
          address: wallet.address
        })

      refute response["success"]
      assert response["data"]["code"] == "unauthorized"
    end

    test "receives an 'unauthorized' error when the token ID is not found" do
      response =
        client_request("/me.create_transaction_request", %{
          type: "send",
          token_id: "123",
          correlation_id: nil,
          amount: nil,
          address: nil
        })

      refute response["success"]
      assert response["data"]["code"] == "unauthorized"
    end

    test "generates an activity log" do
      user = get_test_user()
      token = insert(:token)
      wallet = User.get_primary_wallet(user)

      timestamp = DateTime.utc_now()

      response =
        client_request("/me.create_transaction_request", %{
          type: "send",
          token_id: token.id
        })

      assert response["success"] == true

      request = TransactionRequest.get(response["data"]["id"])

      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 2

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: user,
        target: request,
        changes: %{
          "token_uuid" => token.uuid,
          "type" => "send",
          "user_uuid" => user.uuid,
          "wallet_address" => wallet.address
        },
        encrypted_changes: %{}
      )

      logs
      |> Enum.at(1)
      |> assert_activity_log(
        action: "update",
        originator: :system,
        target: request,
        changes: %{"consumptions_count" => 0},
        encrypted_changes: %{}
      )
    end
  end

  describe "/me.get_transaction_request" do
    test "returns the transaction request" do
      transaction_request = insert(:transaction_request)

      response =
        client_request("/me.get_transaction_request", %{
          formatted_id: transaction_request.id
        })

      assert response["success"] == true
      assert response["data"]["id"] == transaction_request.id
    end

    test "returns :invalid_parameter error when id is not given" do
      response = client_request("/me.get_transaction_request", %{})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `formatted_id` is required."
    end

    test "returns an 'unauthorized' error when the request ID is not found" do
      response =
        client_request("/me.get_transaction_request", %{
          formatted_id: "123"
        })

      assert response["success"] == false
      assert response["data"]["code"] == "unauthorized"
    end
  end

  describe "/me.cancel_transaction_request" do
    test "receives a transaction_request if the owner cancel with valid transaction_request's id" do
      user = get_test_user()
      transaction_request = insert(:transaction_request, user_uuid: user.uuid)

      before_execution = NaiveDateTime.utc_now()

      response =
        client_request("/me.cancel_transaction_request", %{
          formatted_id: transaction_request.id
        })

      # Assert the transaction request is valid
      assert response["success"] == true
      assert response["data"]["id"] == transaction_request.id
      assert response["data"]["status"] == TransactionRequest.expired()

      # Assert there's 1 activity log has been inserted.
      assert [log] = get_all_activity_logs_since(before_execution)

      # Assert changes
      assert log.target_changes == %{
               "status" => TransactionRequest.expired(),
               "expiration_reason" => TransactionRequest.cancelled_transaction_request(),
               "expired_at" => log.target_changes["expired_at"]
             }
    end

    test "receives an error if the owner cancel with invalid transaction_request's id" do
      before_execution = NaiveDateTime.utc_now()

      response =
        client_request("/me.cancel_transaction_request", %{
          formatted_id: "invalid_id"
        })

      assert response == %{
               "data" => %{
                 "code" => "unauthorized",
                 "description" => "You are not allowed to perform the requested operation.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }

      # Assert there's no activity log.
      assert get_all_activity_logs_since(before_execution) == []
    end

    test "receives an error if the id is not given" do
      before_execution = NaiveDateTime.utc_now()

      response = client_request("/me.cancel_transaction_request", %{})

      assert response == %{
               "data" => %{
                 "code" => "client:invalid_parameter",
                 "description" => "Invalid parameter provided. `formatted_id` is required.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }

      # Assert there's no activity log.
      assert get_all_activity_logs_since(before_execution) == []
    end

    test "receives an error if the transaction request does not belong to the user" do
      # Create a transaction request belongs to another user.
      user_tx_request_owner = insert(:user, %{email: "user@example.com"})
      transaction_request = insert(:transaction_request, user_uuid: user_tx_request_owner.uuid)

      before_execution = NaiveDateTime.utc_now()

      # The current user request to cancel the transaction request
      response =
        client_request("/me.cancel_transaction_request", %{
          formatted_id: transaction_request.id
        })

      # Assert the request should failed
      assert response == %{
               "data" => %{
                 "code" => "unauthorized",
                 "description" => "You are not allowed to perform the requested operation.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }

      # Assert there's no activity log.
      assert get_all_activity_logs_since(before_execution) == []
    end
  end
end
