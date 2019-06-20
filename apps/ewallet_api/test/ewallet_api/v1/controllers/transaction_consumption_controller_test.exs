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

defmodule EWalletAPI.V1.TransactionConsumptionControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias EWallet.TestEndpoint
  alias EWallet.Web.Orchestrator
  alias EWalletDB.{Account, Repo, Transaction, TransactionConsumption, User, TransactionRequest}
  alias Phoenix.Socket.Broadcast
  alias Utils.Helpers.DateFormatter

  alias EWallet.Web.V1.{
    TokenSerializer,
    TransactionRequestSerializer,
    TransactionSerializer,
    UserSerializer,
    TransactionConsumptionOverlay
  }

  alias EWalletAPI.V1.Endpoint

  setup do
    {:ok, _} = TestEndpoint.start_link()

    account = Account.get_master_account()
    {:ok, alice} = :user |> params_for() |> User.insert()
    bob = get_test_user()

    %{
      account: account,
      token: insert(:token),
      alice: alice,
      bob: bob,
      account_wallet: Account.get_primary_wallet(account),
      alice_wallet: User.get_primary_wallet(alice),
      bob_wallet: User.get_primary_wallet(bob)
    }
  end

  describe "/me.consume_transaction_request" do
    test "consumes a request with amount and transfers the appropriate amount of tokens", meta do
      transaction_request =
        insert(
          :transaction_request,
          allow_amount_override: false,
          amount: 1 * meta.token.subunit_to_unit,
          correlation_id: "tBUI9WCJ",
          encrypted_metadata: %{"a_key" => "a_value"},
          metadata: %{"a_key" => "a_value"},
          require_confirmation: false,
          token_uuid: meta.token.uuid,
          user_uuid: meta.alice.uuid,
          wallet: meta.alice_wallet,
          type: "send"
        )

      set_initial_balance(%{
        address: meta.alice_wallet.address,
        token: meta.token,
        amount: 150_000
      })

      response =
        client_request("/me.consume_transaction_request", %{
          address: nil,
          encrypted_metadata: %{"a_key" => "a_value"},
          formatted_transaction_request_id: transaction_request.id,
          idempotency_token: "JXcTFKJK",
          metadata: %{"a_key" => "a_value"},
          token_id: meta.token.id
        })

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)

      {:ok, inserted_consumption} =
        Orchestrator.one(inserted_consumption, TransactionConsumptionOverlay)

      request = inserted_consumption.transaction_request
      inserted_transaction = inserted_consumption.transaction

      assert response == %{
               "success" => true,
               "version" => "1",
               "data" => %{
                 "address" => meta.bob_wallet.address,
                 "amount" => nil,
                 "estimated_consumption_amount" => 1 * meta.token.subunit_to_unit,
                 "estimated_request_amount" => 1 * meta.token.subunit_to_unit,
                 "finalized_request_amount" => 1 * meta.token.subunit_to_unit,
                 "finalized_consumption_amount" => 1 * meta.token.subunit_to_unit,
                 "correlation_id" => nil,
                 "id" => inserted_consumption.id,
                 "socket_topic" => "transaction_consumption:#{inserted_consumption.id}",
                 "idempotency_token" => "JXcTFKJK",
                 "object" => "transaction_consumption",
                 "status" => TransactionConsumption.confirmed(),
                 "token_id" => meta.token.id,
                 "token" => meta.token |> TokenSerializer.serialize() |> stringify_keys(),
                 "transaction_request_id" => transaction_request.id,
                 "transaction_request" =>
                   request |> TransactionRequestSerializer.serialize() |> stringify_keys(),
                 "transaction_id" => inserted_transaction.id,
                 "transaction" =>
                   inserted_transaction |> TransactionSerializer.serialize() |> stringify_keys(),
                 "user_id" => meta.bob.id,
                 "user" => meta.bob |> UserSerializer.serialize() |> stringify_keys(),
                 "encrypted_metadata" => %{"a_key" => "a_value"},
                 "expiration_date" => nil,
                 "metadata" => %{"a_key" => "a_value"},
                 "account_id" => nil,
                 "account" => nil,
                 "exchange_account_id" => nil,
                 "exchange_wallet_address" => nil,
                 "exchange_wallet" => nil,
                 "exchange_account" => nil,
                 "created_at" => DateFormatter.to_iso8601(inserted_consumption.inserted_at),
                 "approved_at" => DateFormatter.to_iso8601(inserted_consumption.approved_at),
                 "rejected_at" => DateFormatter.to_iso8601(inserted_consumption.rejected_at),
                 "confirmed_at" => DateFormatter.to_iso8601(inserted_consumption.confirmed_at),
                 "failed_at" => DateFormatter.to_iso8601(inserted_consumption.failed_at),
                 "expired_at" => nil,
                 "cancelled_at" => nil
               }
             }

      assert inserted_transaction.from_amount == 1 * meta.token.subunit_to_unit
      assert inserted_transaction.to_amount == 1 * meta.token.subunit_to_unit
      assert inserted_transaction.to == meta.bob_wallet.address
      assert inserted_transaction.from == meta.alice_wallet.address
      assert inserted_transaction.local_ledger_uuid != nil
    end

    test "consumes the request and transfers the appropriate amount of tokens", meta do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: meta.token.uuid,
          user_uuid: meta.alice.uuid,
          wallet: meta.alice_wallet,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      set_initial_balance(%{
        address: meta.bob_wallet.address,
        token: meta.token,
        amount: 150_000
      })

      response =
        client_request("/me.consume_transaction_request", %{
          idempotency_token: "JXcTFKJK",
          address: nil,
          metadata: %{"a_key" => "a_value"},
          encrypted_metadata: %{"a_key" => "a_value"},
          formatted_transaction_request_id: transaction_request.id,
          token_id: meta.token.id
        })

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)

      {:ok, inserted_consumption} =
        Orchestrator.one(inserted_consumption, TransactionConsumptionOverlay)

      request = inserted_consumption.transaction_request
      inserted_transaction = inserted_consumption.transaction

      assert response == %{
               "success" => true,
               "version" => "1",
               "data" => %{
                 "address" => meta.bob_wallet.address,
                 "amount" => nil,
                 "estimated_consumption_amount" => 100_000 * meta.token.subunit_to_unit,
                 "estimated_request_amount" => 100_000 * meta.token.subunit_to_unit,
                 "finalized_request_amount" => 100_000 * meta.token.subunit_to_unit,
                 "finalized_consumption_amount" => 100_000 * meta.token.subunit_to_unit,
                 "correlation_id" => nil,
                 "id" => inserted_consumption.id,
                 "socket_topic" => "transaction_consumption:#{inserted_consumption.id}",
                 "idempotency_token" => "JXcTFKJK",
                 "object" => "transaction_consumption",
                 "status" => TransactionConsumption.confirmed(),
                 "token_id" => meta.token.id,
                 "token" => meta.token |> TokenSerializer.serialize() |> stringify_keys(),
                 "transaction_request_id" => transaction_request.id,
                 "transaction_request" =>
                   request |> TransactionRequestSerializer.serialize() |> stringify_keys(),
                 "transaction_id" => inserted_transaction.id,
                 "transaction" =>
                   inserted_transaction |> TransactionSerializer.serialize() |> stringify_keys(),
                 "user_id" => meta.bob.id,
                 "user" => meta.bob |> UserSerializer.serialize() |> stringify_keys(),
                 "encrypted_metadata" => %{"a_key" => "a_value"},
                 "expiration_date" => nil,
                 "metadata" => %{"a_key" => "a_value"},
                 "account_id" => nil,
                 "account" => nil,
                 "exchange_account_id" => nil,
                 "exchange_wallet_address" => nil,
                 "exchange_wallet" => nil,
                 "exchange_account" => nil,
                 "created_at" => DateFormatter.to_iso8601(inserted_consumption.inserted_at),
                 "approved_at" => DateFormatter.to_iso8601(inserted_consumption.approved_at),
                 "rejected_at" => DateFormatter.to_iso8601(inserted_consumption.rejected_at),
                 "confirmed_at" => DateFormatter.to_iso8601(inserted_consumption.confirmed_at),
                 "failed_at" => DateFormatter.to_iso8601(inserted_consumption.failed_at),
                 "expired_at" => nil,
                 "cancelled_at" => nil
               }
             }

      assert inserted_transaction.from_amount == 100_000 * meta.token.subunit_to_unit
      assert inserted_transaction.to_amount == 100_000 * meta.token.subunit_to_unit
      assert inserted_transaction.to == meta.alice_wallet.address
      assert inserted_transaction.from == meta.bob_wallet.address
      assert inserted_transaction.local_ledger_uuid != nil
    end

    test "consumes the request and transfers the appropriate amount of tokens with min params",
         meta do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: meta.token.uuid,
          user_uuid: meta.alice.uuid,
          wallet: meta.alice_wallet,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      set_initial_balance(%{
        address: meta.bob_wallet.address,
        token: meta.token,
        amount: 150_000
      })

      response =
        client_request("/me.consume_transaction_request", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id
        })

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)

      {:ok, inserted_consumption} =
        Orchestrator.one(inserted_consumption, TransactionConsumptionOverlay)

      request = inserted_consumption.transaction_request
      inserted_transaction = inserted_consumption.transaction

      assert response == %{
               "success" => true,
               "version" => "1",
               "data" => %{
                 "address" => meta.bob_wallet.address,
                 "amount" => nil,
                 "estimated_consumption_amount" => 100_000 * meta.token.subunit_to_unit,
                 "estimated_request_amount" => 100_000 * meta.token.subunit_to_unit,
                 "finalized_request_amount" => 100_000 * meta.token.subunit_to_unit,
                 "finalized_consumption_amount" => 100_000 * meta.token.subunit_to_unit,
                 "correlation_id" => nil,
                 "id" => inserted_consumption.id,
                 "socket_topic" => "transaction_consumption:#{inserted_consumption.id}",
                 "idempotency_token" => "123",
                 "object" => "transaction_consumption",
                 "status" => TransactionConsumption.confirmed(),
                 "token_id" => meta.token.id,
                 "token" => meta.token |> TokenSerializer.serialize() |> stringify_keys(),
                 "transaction_request_id" => transaction_request.id,
                 "transaction_request" =>
                   request |> TransactionRequestSerializer.serialize() |> stringify_keys(),
                 "transaction_id" => inserted_transaction.id,
                 "transaction" =>
                   inserted_transaction |> TransactionSerializer.serialize() |> stringify_keys(),
                 "user_id" => meta.bob.id,
                 "user" => meta.bob |> UserSerializer.serialize() |> stringify_keys(),
                 "encrypted_metadata" => %{},
                 "expiration_date" => nil,
                 "metadata" => %{},
                 "account_id" => nil,
                 "account" => nil,
                 "exchange_account_id" => nil,
                 "exchange_wallet_address" => nil,
                 "exchange_wallet" => nil,
                 "exchange_account" => nil,
                 "created_at" => DateFormatter.to_iso8601(inserted_consumption.inserted_at),
                 "approved_at" => DateFormatter.to_iso8601(inserted_consumption.approved_at),
                 "rejected_at" => DateFormatter.to_iso8601(inserted_consumption.rejected_at),
                 "confirmed_at" => DateFormatter.to_iso8601(inserted_consumption.confirmed_at),
                 "failed_at" => DateFormatter.to_iso8601(inserted_consumption.failed_at),
                 "expired_at" => nil,
                 "cancelled_at" => nil
               }
             }

      assert inserted_transaction.to_amount == 100_000 * meta.token.subunit_to_unit
      assert inserted_transaction.from_amount == 100_000 * meta.token.subunit_to_unit
      assert inserted_transaction.to == meta.alice_wallet.address
      assert inserted_transaction.from == meta.bob_wallet.address
      assert inserted_transaction.local_ledger_uuid != nil
    end

    test "consumes the request and transfers the appropriate amount of tokens with min nil params",
         meta do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: meta.token.uuid,
          user_uuid: meta.alice.uuid,
          wallet: meta.alice_wallet,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      set_initial_balance(%{
        address: meta.bob_wallet.address,
        token: meta.token,
        amount: 150_000
      })

      response =
        client_request("/me.consume_transaction_request", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil
        })

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)

      {:ok, inserted_consumption} =
        Orchestrator.one(inserted_consumption, TransactionConsumptionOverlay)

      request = inserted_consumption.transaction_request
      inserted_transaction = inserted_consumption.transaction

      assert response == %{
               "success" => true,
               "version" => "1",
               "data" => %{
                 "address" => meta.bob_wallet.address,
                 "amount" => nil,
                 "estimated_consumption_amount" => 100_000 * meta.token.subunit_to_unit,
                 "estimated_request_amount" => 100_000 * meta.token.subunit_to_unit,
                 "finalized_request_amount" => 100_000 * meta.token.subunit_to_unit,
                 "finalized_consumption_amount" => 100_000 * meta.token.subunit_to_unit,
                 "correlation_id" => nil,
                 "id" => inserted_consumption.id,
                 "socket_topic" => "transaction_consumption:#{inserted_consumption.id}",
                 "idempotency_token" => "123",
                 "object" => "transaction_consumption",
                 "status" => TransactionConsumption.confirmed(),
                 "token_id" => meta.token.id,
                 "token" => meta.token |> TokenSerializer.serialize() |> stringify_keys(),
                 "transaction_request_id" => transaction_request.id,
                 "transaction_request" =>
                   request |> TransactionRequestSerializer.serialize() |> stringify_keys(),
                 "transaction_id" => inserted_transaction.id,
                 "transaction" =>
                   inserted_transaction |> TransactionSerializer.serialize() |> stringify_keys(),
                 "user_id" => meta.bob.id,
                 "user" => meta.bob |> UserSerializer.serialize() |> stringify_keys(),
                 "encrypted_metadata" => %{},
                 "expiration_date" => nil,
                 "metadata" => %{},
                 "account_id" => nil,
                 "account" => nil,
                 "exchange_account_id" => nil,
                 "exchange_wallet_address" => nil,
                 "exchange_wallet" => nil,
                 "exchange_account" => nil,
                 "created_at" => DateFormatter.to_iso8601(inserted_consumption.inserted_at),
                 "approved_at" => DateFormatter.to_iso8601(inserted_consumption.approved_at),
                 "rejected_at" => DateFormatter.to_iso8601(inserted_consumption.rejected_at),
                 "confirmed_at" => DateFormatter.to_iso8601(inserted_consumption.confirmed_at),
                 "failed_at" => DateFormatter.to_iso8601(inserted_consumption.failed_at),
                 "expired_at" => nil,
                 "cancelled_at" => nil
               }
             }

      assert inserted_transaction.from_amount == 100_000 * meta.token.subunit_to_unit
      assert inserted_transaction.from_token_uuid == meta.token.uuid
      assert inserted_transaction.to_amount == 100_000 * meta.token.subunit_to_unit
      assert inserted_transaction.to_token_uuid == meta.token.uuid
      assert inserted_transaction.to == meta.alice_wallet.address
      assert inserted_transaction.from == meta.bob_wallet.address
      assert inserted_transaction.local_ledger_uuid != nil
    end

    test "returns same transaction request consumption when idempotency token is the same",
         meta do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: meta.token.uuid,
          user_uuid: meta.alice.uuid,
          wallet: meta.alice_wallet,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      set_initial_balance(%{
        address: meta.bob_wallet.address,
        token: meta.token,
        amount: 150_000
      })

      response =
        client_request("/me.consume_transaction_request", %{
          idempotency_token: "1234",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil
        })

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transaction = Repo.get(Transaction, inserted_consumption.transaction_uuid)

      assert response["success"] == true
      assert response["data"]["id"] == inserted_consumption.id

      response =
        client_request("/me.consume_transaction_request", %{
          idempotency_token: "1234",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil
        })

      inserted_consumption_2 = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transaction_2 = Repo.get(Transaction, inserted_consumption.transaction_uuid)

      assert response["success"] == true
      assert response["data"]["id"] == inserted_consumption_2.id
      assert inserted_consumption.uuid == inserted_consumption_2.uuid
      assert inserted_transaction.uuid == inserted_transaction_2.uuid
    end

    test "returns a max_consumption_per_interval_reached error", meta do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: meta.token.uuid,
          user_uuid: meta.alice.uuid,
          wallet: meta.alice_wallet,
          amount: 100_000 * meta.token.subunit_to_unit,
          consumption_interval_duration: 360_000_000,
          max_consumptions_per_interval_per_user: 1
        )

      set_initial_balance(%{
        address: meta.bob_wallet.address,
        token: meta.token,
        amount: 150_000
      })

      response =
        client_request("/me.consume_transaction_request", %{
          idempotency_token: "1234",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil
        })

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)

      assert response["success"] == true
      assert response["data"]["id"] == inserted_consumption.id

      response =
        client_request("/me.consume_transaction_request", %{
          idempotency_token: "12345",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil
        })

      refute response["success"]

      assert response["data"]["code"] ==
               "transaction_request:max_consumptions_per_interval_per_user_reached"
    end

    test "sends socket confirmation when require_confirmation and approved between users", meta do
      # bob = test_user
      set_initial_balance(%{
        address: meta.bob_wallet.address,
        token: meta.token,
        amount: 1_000_000 * meta.token.subunit_to_unit
      })

      # Create a require_confirmation transaction request that will be consumed soon
      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          token_uuid: meta.token.uuid,
          account_uuid: meta.account.uuid,
          user_uuid: meta.bob.uuid,
          wallet: meta.bob_wallet,
          amount: nil,
          require_confirmation: true
        )

      request_topic = "transaction_request:#{transaction_request.id}"

      # Start listening to the channels for the transaction request created above
      Endpoint.subscribe(request_topic)

      # Making the consumption, since we made the request require_confirmation, it will
      # create a pending consumption that will need to be confirmed

      auth_token =
        insert(:auth_token, %{
          user: meta.alice,
          account: meta.account,
          token: "test_token_2",
          owner_app: "ewallet_api"
        })

      data = %{
        idempotency_token: "12342",
        formatted_transaction_request_id: transaction_request.id,
        correlation_id: nil,
        amount: 100_000 * meta.token.subunit_to_unit,
        metadata: nil,
        token_id: nil,
        address: meta.alice_wallet.address
      }

      response =
        build_conn()
        |> put_req_header("accept", @header_accept)
        |> put_auth_header("OMGClient", @api_key, auth_token.token)
        |> post(@base_dir <> "/me.consume_transaction_request", data)
        |> json_response(:ok)

      consumption_id = response["data"]["id"]
      assert response["success"] == true
      assert response["data"]["status"] == "pending"
      assert response["data"]["transaction_id"] == nil

      # Retrieve what just got inserted
      inserted_consumption = TransactionConsumption.get(response["data"]["id"])

      # We check that we receive the confirmation request above in the
      # transaction request channel
      assert_receive %Broadcast{
        event: "transaction_consumption_request",
        topic: "transaction_request:" <> _,
        payload:
          %{
            # Ignore content
          }
      }

      # We need to know once the consumption has been approved, so let's
      # listen to the channel for it
      Endpoint.subscribe("transaction_consumption:#{consumption_id}")

      # Confirm the consumption
      response =
        client_request("/me.approve_transaction_consumption", %{
          id: consumption_id
        })

      assert response["success"] == true
      assert response["data"]["id"] == inserted_consumption.id
      assert response["data"]["status"] == TransactionConsumption.confirmed()
      assert response["data"]["approved_at"] != nil
      assert response["data"]["confirmed_at"] != nil

      # Check that a transaction was inserted
      inserted_transaction = Repo.get_by(Transaction, id: response["data"]["transaction_id"])
      assert inserted_transaction.from_amount == 100_000 * meta.token.subunit_to_unit
      assert inserted_transaction.from_token_uuid == meta.token.uuid
      assert inserted_transaction.to_amount == 100_000 * meta.token.subunit_to_unit
      assert inserted_transaction.to_token_uuid == meta.token.uuid
      assert inserted_transaction.to == meta.alice_wallet.address
      assert inserted_transaction.from == meta.bob_wallet.address
      assert inserted_transaction.local_ledger_uuid != nil

      assert_receive %Broadcast{
        event: "transaction_consumption_finalized",
        topic: "transaction_consumption:" <> _,
        payload:
          %{
            # Ignore content
          }
      }

      # Unsubscribe from all channels
      Endpoint.unsubscribe("transaction_request:#{transaction_request.id}")
      Endpoint.unsubscribe("transaction_consumption:#{consumption_id}")
    end

    test "returns idempotency error if idempotency token is missing" do
      response =
        client_request("/me.consume_transaction_request", %{
          transaction_request_id: "123",
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "client:invalid_parameter",
                 "description" => "Invalid parameter provided. `idempotency_token` is required",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test "fails to consume a comsumption that involves exchange",
         meta do
      account = Account.get_master_account()
      token_2 = insert(:token)
      insert(:exchange_pair, from_token: meta.token, to_token: token_2)
      mint!(token_2)

      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          token_uuid: meta.token.uuid,
          user_uuid: meta.alice.uuid,
          wallet: meta.alice_wallet,
          amount: 100_000 * meta.token.subunit_to_unit,
          exchange_account_uuid: account.uuid
        )

      set_initial_balance(%{
        address: meta.alice_wallet.address,
        token: meta.token,
        amount: 150_000
      })

      response =
        client_request("/me.consume_transaction_request", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          token_id: token_2.id
        })

      assert response["success"] == false
    end

    test "generates an activity log", meta do
      transaction_request =
        insert(
          :transaction_request,
          allow_amount_override: false,
          amount: 1 * meta.token.subunit_to_unit,
          correlation_id: "tBUI9WCJ",
          encrypted_metadata: %{"a_key" => "a_value"},
          metadata: %{"a_key" => "a_value"},
          require_confirmation: false,
          token_uuid: meta.token.uuid,
          user_uuid: meta.alice.uuid,
          wallet: meta.alice_wallet,
          type: "send"
        )

      set_initial_balance(%{
        address: meta.alice_wallet.address,
        token: meta.token,
        amount: 150_000
      })

      timestamp = DateTime.utc_now()

      response =
        client_request("/me.consume_transaction_request", %{
          address: nil,
          encrypted_metadata: %{"a_key" => "a_value"},
          formatted_transaction_request_id: transaction_request.id,
          idempotency_token: "JXcTFKJK",
          metadata: %{"a_key" => "a_value"},
          token_id: meta.token.id
        })

      assert response["success"] == true

      transaction_request = TransactionRequest.get(transaction_request.id)
      transaction_consumption = TransactionConsumption.get(response["data"]["id"])
      transaction = get_last_inserted(Transaction)
      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 7

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: meta.bob,
        target: transaction_consumption,
        changes: %{
          "estimated_at" => DateFormatter.to_iso8601(transaction_consumption.estimated_at),
          "estimated_consumption_amount" => 100,
          "estimated_rate" => 1.0,
          "estimated_request_amount" => 100,
          "idempotency_token" => "JXcTFKJK",
          "token_uuid" => meta.token.uuid,
          "transaction_request_uuid" => transaction_request.uuid,
          "wallet_address" => meta.bob_wallet.address,
          "metadata" => %{"a_key" => "a_value"},
          "user_uuid" => meta.bob.uuid
        },
        encrypted_changes: %{"encrypted_metadata" => %{"a_key" => "a_value"}}
      )

      logs
      |> Enum.at(1)
      |> assert_activity_log(
        action: "update",
        originator: :system,
        target: transaction_consumption,
        changes: %{
          "approved_at" => DateFormatter.to_iso8601(transaction_consumption.approved_at),
          "status" => "approved"
        },
        encrypted_changes: %{}
      )

      logs
      |> Enum.at(2)
      |> assert_activity_log(
        action: "insert",
        originator: transaction_consumption,
        target: transaction,
        changes: %{
          "calculated_at" => DateFormatter.to_iso8601(transaction.calculated_at),
          "from" => meta.alice_wallet.address,
          "from_user_uuid" => meta.alice.uuid,
          "from_amount" => 100,
          "from_token_uuid" => meta.token.uuid,
          "idempotency_token" => "JXcTFKJK",
          "rate" => 1.0,
          "to" => meta.bob_wallet.address,
          "to_amount" => 100,
          "to_token_uuid" => meta.token.uuid,
          "to_user_uuid" => meta.bob.uuid,
          "metadata" => %{"a_key" => "a_value"}
        },
        encrypted_changes: %{
          "payload" => %{
            "encrypted_metadata" => %{"a_key" => "a_value"},
            "exchange_account_id" => nil,
            "exchange_wallet_address" => nil,
            "from_address" => meta.alice_wallet.address,
            "from_amount" => 100,
            "from_token_id" => meta.token.id,
            "idempotency_token" => "JXcTFKJK",
            "metadata" => %{"a_key" => "a_value"},
            "to_address" => meta.bob_wallet.address,
            "to_amount" => 100,
            "to_token_id" => meta.token.id
          },
          "encrypted_metadata" => %{"a_key" => "a_value"}
        }
      )

      logs
      |> Enum.at(3)
      |> assert_activity_log(
        action: "update",
        originator: :system,
        target: transaction,
        changes: %{
          "local_ledger_uuid" => transaction.local_ledger_uuid,
          "status" => TransactionConsumption.confirmed()
        },
        encrypted_changes: %{}
      )

      logs
      |> Enum.at(4)
      |> assert_activity_log(
        action: "update",
        originator: transaction,
        target: transaction_consumption,
        changes: %{
          "confirmed_at" => DateFormatter.to_iso8601(transaction_consumption.confirmed_at),
          "status" => TransactionConsumption.confirmed(),
          "transaction_uuid" => transaction.uuid
        },
        encrypted_changes: %{}
      )

      logs
      |> Enum.at(5)
      |> assert_activity_log(
        action: "update",
        originator: :system,
        target: transaction_request,
        changes: %{"consumptions_count" => 1},
        encrypted_changes: %{}
      )

      logs
      |> Enum.at(6)
      |> assert_activity_log(
        action: "update",
        originator: :system,
        target: transaction_request,
        changes: %{"updated_at" => DateFormatter.to_iso8601(transaction_request.updated_at)},
        encrypted_changes: %{}
      )
    end
  end

  describe "/me.cancel_transaction_consumption" do
    test "cancels a consumption when in pending state" do
      transaction_consumption =
        insert(:transaction_consumption, %{user_uuid: get_test_user().uuid, status: "pending"})

      response =
        client_request("/me.cancel_transaction_consumption", %{
          id: transaction_consumption.id
        })

      assert response["success"]
      assert response["data"]["id"] == transaction_consumption.id
      assert response["data"]["cancelled_at"] != nil
      assert response["data"]["status"] == TransactionConsumption.cancelled()
    end

    test "returns a 'transaction_consumption:uncancellable' error when the consumption is not pending" do
      transaction_consumption =
        insert(:transaction_consumption, %{
          user_uuid: get_test_user().uuid,
          status: TransactionConsumption.confirmed()
        })

      response =
        client_request("/me.cancel_transaction_consumption", %{
          id: transaction_consumption.id
        })

      refute response["success"]
      assert response["data"]["code"] == "transaction_consumption:uncancellable"
    end

    test "sends socket confirmation when cancelling", context do
      mint!(context.token)

      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          token_uuid: context.token.uuid,
          account_uuid: context.account.uuid,
          wallet: context.account_wallet,
          amount: nil,
          require_confirmation: true
        )

      request_topic = "transaction_request:#{transaction_request.id}"

      # Start listening to the channels for the transaction request created above
      Endpoint.subscribe(request_topic)

      # Making the consumption, since we made the request require_confirmation, it will
      # create a pending consumption that we will cancel
      response =
        client_request("/me.consume_transaction_request", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: 100_000 * context.token.subunit_to_unit,
          metadata: nil,
          token_id: nil,
          provider_user_id: @provider_user_id
        })

      consumption_id = response["data"]["id"]
      assert response["success"]
      assert response["data"]["status"] == "pending"

      # Retrieve what just got inserted
      inserted_consumption = TransactionConsumption.get(response["data"]["id"])

      # We check that we receive the confirmation request above in the
      # transaction request channel
      assert_receive %Phoenix.Socket.Broadcast{
        event: "transaction_consumption_request",
        topic: "transaction_request:" <> _,
        payload:
          %{
            # Ignore content
          }
      }

      # We need to know once the consumption has been cancelled, so let's
      # listen to the channel for it
      Endpoint.subscribe("transaction_consumption:#{consumption_id}")

      # Cancel the consumption
      response =
        client_request("/me.cancel_transaction_consumption", %{
          id: consumption_id
        })

      assert response["success"]
      assert response["data"]["id"] == inserted_consumption.id
      assert response["data"]["status"] == TransactionConsumption.cancelled()
      assert response["data"]["cancelled_at"] != nil

      assert_receive %Phoenix.Socket.Broadcast{
        event: "transaction_consumption_finalized",
        topic: "transaction_consumption:" <> _,
        payload:
          %{
            # Ignore content
          }
      }

      # Unsubscribe from all channels
      Endpoint.unsubscribe("transaction_request:#{transaction_request.id}")
      Endpoint.unsubscribe("transaction_consumption:#{consumption_id}")
    end

    defp assert_cancel_logs(logs, originator, transaction_consumption) do
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: originator,
        target: transaction_consumption,
        changes: %{
          "status" => transaction_consumption.status,
          "cancelled_at" => DateFormatter.to_iso8601(transaction_consumption.cancelled_at)
        },
        encrypted_changes: %{}
      )
    end

    test "generates an activity log" do
      transaction_consumption =
        insert(:transaction_consumption, %{user_uuid: get_test_user().uuid, status: "pending"})

      timestamp = DateTime.utc_now()

      response =
        client_request("/me.cancel_transaction_consumption", %{
          id: transaction_consumption.id
        })

      assert response["success"] == true

      transaction_consumption = TransactionConsumption.get(transaction_consumption.id)

      timestamp
      |> get_all_activity_logs_since()
      |> assert_cancel_logs(get_test_user(), transaction_consumption)
    end
  end
end
