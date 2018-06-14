defmodule EWalletAPI.V1.TransactionConsumptionControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias EWalletDB.{Repo, TransactionRequest, TransactionConsumption, User, Transfer, Account}
  alias EWallet.TestEndpoint
  alias EWallet.Web.Date
  alias Phoenix.Socket.Broadcast

  alias EWallet.Web.V1.{
    TokenSerializer,
    TransactionRequestSerializer,
    TransactionSerializer,
    UserSerializer
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
        client_request_with_idempotency("/me.consume_transaction_request", "123", %{
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil
        })

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transfer = Repo.get(Transfer, inserted_consumption.transfer_uuid)
      request = TransactionRequest.get(transaction_request.id, preload: [:token])

      assert response == %{
               "success" => true,
               "version" => "1",
               "data" => %{
                 "address" => meta.bob_wallet.address,
                 "amount" => 100_000 * meta.token.subunit_to_unit,
                 "correlation_id" => nil,
                 "id" => inserted_consumption.id,
                 "socket_topic" => "transaction_consumption:#{inserted_consumption.id}",
                 "idempotency_token" => "123",
                 "object" => "transaction_consumption",
                 "status" => "confirmed",
                 "token_id" => meta.token.id,
                 "token" => meta.token |> TokenSerializer.serialize() |> stringify_keys(),
                 "transaction_request_id" => transaction_request.id,
                 "transaction_request" =>
                   request |> TransactionRequestSerializer.serialize() |> stringify_keys(),
                 "transaction_id" => inserted_transfer.id,
                 "transaction" =>
                   inserted_transfer |> TransactionSerializer.serialize() |> stringify_keys(),
                 "user_id" => meta.bob.id,
                 "user" => meta.bob |> UserSerializer.serialize() |> stringify_keys(),
                 "encrypted_metadata" => %{},
                 "expiration_date" => nil,
                 "metadata" => %{},
                 "account_id" => nil,
                 "account" => nil,
                 "created_at" => Date.to_iso8601(inserted_consumption.inserted_at),
                 "approved_at" => Date.to_iso8601(inserted_consumption.approved_at),
                 "rejected_at" => Date.to_iso8601(inserted_consumption.rejected_at),
                 "confirmed_at" => Date.to_iso8601(inserted_consumption.confirmed_at),
                 "failed_at" => Date.to_iso8601(inserted_consumption.failed_at),
                 "expired_at" => nil
               }
             }

      assert inserted_transfer.amount == 100_000 * meta.token.subunit_to_unit
      assert inserted_transfer.to == meta.alice_wallet.address
      assert inserted_transfer.from == meta.bob_wallet.address
      assert inserted_transfer.entry_uuid != nil
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
        client_request_with_idempotency("/me.consume_transaction_request", "1234", %{
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil
        })

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transfer = Repo.get(Transfer, inserted_consumption.transfer_uuid)

      assert response["success"] == true
      assert response["data"]["id"] == inserted_consumption.id

      response =
        client_request_with_idempotency("/me.consume_transaction_request", "1234", %{
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil
        })

      inserted_consumption_2 = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transfer_2 = Repo.get(Transfer, inserted_consumption.transfer_uuid)

      assert response["success"] == true
      assert response["data"]["id"] == inserted_consumption_2.id
      assert inserted_consumption.uuid == inserted_consumption_2.uuid
      assert inserted_transfer.uuid == inserted_transfer_2.uuid
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
        formatted_transaction_request_id: transaction_request.id,
        correlation_id: nil,
        amount: 100_000 * meta.token.subunit_to_unit,
        metadata: nil,
        token_id: nil,
        address: meta.alice_wallet.address
      }

      response =
        build_conn()
        |> put_req_header("idempotency-token", "12342")
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
      assert response["data"]["status"] == "confirmed"
      assert response["data"]["approved_at"] != nil
      assert response["data"]["confirmed_at"] != nil

      # Check that a transfer was inserted
      inserted_transfer = Repo.get_by(Transfer, id: response["data"]["transaction_id"])
      assert inserted_transfer.amount == 100_000 * meta.token.subunit_to_unit
      assert inserted_transfer.to == meta.alice_wallet.address
      assert inserted_transfer.from == meta.bob_wallet.address
      assert inserted_transfer.entry_uuid != nil

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

    test "returns idempotency error if header is not specified" do
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
                 "code" => "client:no_idempotency_token_provided",
                 "description" =>
                   "The call you made requires the " <>
                     "Idempotency-Token header to prevent duplication.",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end
  end
end
