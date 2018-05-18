defmodule EWalletAPI.V1.TransactionConsumptionControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias EWalletDB.{Repo, TransactionRequest, TransactionConsumption, User, Transfer, Account}
  alias EWallet.TestEndpoint
  alias EWallet.Web.{Date, V1.WebsocketResponseSerializer}
  alias Phoenix.Socket.Broadcast

  alias EWallet.Web.V1.{
    AccountSerializer,
    MintedTokenSerializer,
    TransactionRequestSerializer,
    TransactionSerializer,
    UserSerializer
  }

  alias EWallet.TransactionConsumptionScheduler
  alias EWalletAPI.V1.Endpoint

  setup do
    {:ok, _} = TestEndpoint.start_link()

    account = Account.get_master_account()
    {:ok, alice} = :user |> params_for() |> User.insert()
    bob = get_test_user()

    %{
      account: account,
      minted_token: insert(:minted_token),
      alice: alice,
      bob: bob,
      account_wallet: Account.get_primary_wallet(account),
      alice_wallet: User.get_primary_wallet(alice),
      bob_wallet: User.get_primary_wallet(bob)
    }
  end

  describe "/transaction_request.consume" do
    test "consumes the request and transfers the appropriate amount of tokens", meta do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          minted_token_uuid: meta.minted_token.uuid,
          user_uuid: meta.alice.uuid,
          wallet: meta.alice_wallet,
          amount: 100_000 * meta.minted_token.subunit_to_unit
        )

      set_initial_balance(%{
        address: meta.bob_wallet.address,
        minted_token: meta.minted_token,
        amount: 150_000
      })

      response =
        provider_request_with_idempotency("/transaction_request.consume", "123", %{
          transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil,
          account_id: meta.account.id
        })

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transfer = Repo.get(Transfer, inserted_consumption.transfer_uuid)
      request = TransactionRequest.get(transaction_request.id, preload: [:minted_token])

      assert response == %{
               "success" => true,
               "version" => "1",
               "data" => %{
                 "address" => meta.account_wallet.address,
                 "amount" => 100_000 * meta.minted_token.subunit_to_unit,
                 "correlation_id" => nil,
                 "id" => inserted_consumption.id,
                 "socket_topic" => "transaction_consumption:#{inserted_consumption.id}",
                 "idempotency_token" => "123",
                 "object" => "transaction_consumption",
                 "status" => "confirmed",
                 "minted_token_id" => meta.minted_token.id,
                 "minted_token" =>
                   meta.minted_token |> MintedTokenSerializer.serialize() |> stringify_keys(),
                 "transaction_request_id" => transaction_request.id,
                 "transaction_request" =>
                   request |> TransactionRequestSerializer.serialize() |> stringify_keys(),
                 "transaction_id" => inserted_transfer.id,
                 "transaction" =>
                   inserted_transfer |> TransactionSerializer.serialize() |> stringify_keys(),
                 "user_id" => nil,
                 "user" => nil,
                 "account_id" => meta.account.id,
                 "account" => meta.account |> AccountSerializer.serialize() |> stringify_keys(),
                 "metadata" => %{},
                 "encrypted_metadata" => %{},
                 "expiration_date" => nil,
                 "created_at" => Date.to_iso8601(inserted_consumption.inserted_at),
                 "approved_at" => Date.to_iso8601(inserted_consumption.approved_at),
                 "rejected_at" => Date.to_iso8601(inserted_consumption.rejected_at),
                 "confirmed_at" => Date.to_iso8601(inserted_consumption.confirmed_at),
                 "failed_at" => Date.to_iso8601(inserted_consumption.failed_at),
                 "expired_at" => nil
               }
             }

      assert inserted_transfer.amount == 100_000 * meta.minted_token.subunit_to_unit
      assert inserted_transfer.to == meta.alice_wallet.address
      assert inserted_transfer.from == meta.account_wallet.address
      assert %{} = inserted_transfer.ledger_response
    end

    test "fails to consume and return an insufficient funds error", meta do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          minted_token_uuid: meta.minted_token.uuid,
          user_uuid: meta.alice.uuid,
          balance: meta.alice_balance,
          amount: 100_000 * meta.minted_token.subunit_to_unit
        )

      response =
        provider_request_with_idempotency("/transaction_request.consume", "123", %{
          transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil,
          account_id: meta.account.id
        })

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transfer = Repo.get(Transfer, inserted_consumption.transfer_uuid)

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "object" => "error",
                 "messages" => nil,
                 "code" => "transaction:insufficient_funds",
                 "description" =>
                   "The specified balance (#{meta.account_balance.address}) does not contain enough funds. Available: 0.0 #{
                     meta.minted_token.id
                   } - Attempted debit: 100000.0 #{meta.minted_token.id}"
               }
             }

      assert inserted_transfer.amount == 100_000 * meta.minted_token.subunit_to_unit
      assert inserted_transfer.to == meta.alice_balance.address
      assert inserted_transfer.from == meta.account_balance.address
      assert %{} = inserted_transfer.ledger_response
    end

    test "returns with preload if `embed` attribute is given", meta do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          minted_token_uuid: meta.minted_token.uuid,
          user_uuid: meta.alice.uuid,
          wallet: meta.alice_wallet,
          amount: 100_000 * meta.minted_token.subunit_to_unit
        )

      set_initial_balance(%{
        address: meta.bob_wallet.address,
        minted_token: meta.minted_token,
        amount: 150_000
      })

      response =
        provider_request_with_idempotency("/transaction_request.consume", "123", %{
          transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil,
          account_id: meta.account.id,
          embed: ["account"]
        })

      assert response["data"]["account"] != nil
    end

    test "returns same transaction request consumption when idempotency token is the same",
         meta do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          minted_token_uuid: meta.minted_token.uuid,
          user_uuid: meta.alice.uuid,
          wallet: meta.alice_wallet,
          amount: 100_000 * meta.minted_token.subunit_to_unit
        )

      set_initial_balance(%{
        address: meta.bob_wallet.address,
        minted_token: meta.minted_token,
        amount: 150_000
      })

      response =
        provider_request_with_idempotency("/transaction_request.consume", "1234", %{
          transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil,
          account_id: meta.account.id
        })

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transfer = Repo.get(Transfer, inserted_consumption.transfer_uuid)

      assert response["success"] == true
      assert response["data"]["id"] == inserted_consumption.id

      response =
        client_request_with_idempotency("/me.consume_transaction_request", "1234", %{
          transaction_request_id: transaction_request.id,
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

    test "sends socket confirmation when require_confirmation and approved", meta do
      mint!(meta.minted_token)

      # Create a require_confirmation transaction request that will be consumed soon
      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          minted_token_uuid: meta.minted_token.uuid,
          account_uuid: meta.account.uuid,
          wallet: meta.account_wallet,
          amount: nil,
          require_confirmation: true
        )

      request_topic = "transaction_request:#{transaction_request.id}"

      # Start listening to the channels for the transaction request created above
      Endpoint.subscribe(request_topic)

      # Making the consumption, since we made the request require_confirmation, it will
      # create a pending consumption that will need to be confirmed
      response =
        provider_request_with_idempotency("/transaction_request.consume", "123", %{
          transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: 100_000 * meta.minted_token.subunit_to_unit,
          metadata: nil,
          token_id: nil,
          provider_user_id: meta.bob.provider_user_id
        })

      consumption_id = response["data"]["id"]
      assert response["success"] == true
      assert response["data"]["status"] == "pending"
      assert response["data"]["transaction_id"] == nil

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

      # We need to know once the consumption has been approved, so let's
      # listen to the channel for it
      Endpoint.subscribe("transaction_consumption:#{consumption_id}")

      # Confirm the consumption
      response =
        provider_request("/transaction_consumption.approve", %{
          id: consumption_id
        })

      assert response["success"] == true
      assert response["data"]["id"] == inserted_consumption.id
      assert response["data"]["status"] == "confirmed"
      assert response["data"]["approved_at"] != nil
      assert response["data"]["confirmed_at"] != nil

      # Check that a transfer was inserted
      inserted_transfer = Repo.get_by(Transfer, id: response["data"]["transaction_id"])
      assert inserted_transfer.amount == 100_000 * meta.minted_token.subunit_to_unit
      assert inserted_transfer.to == meta.bob_wallet.address
      assert inserted_transfer.from == meta.account_wallet.address
      assert %{} = inserted_transfer.ledger_response

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

    test "sends socket confirmation when require_confirmation and approved between users", meta do
      # bob = test_user
      set_initial_balance(%{
        address: meta.bob_wallet.address,
        minted_token: meta.minted_token,
        amount: 1_000_000 * meta.minted_token.subunit_to_unit
      })

      # Create a require_confirmation transaction request that will be consumed soon
      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          minted_token_uuid: meta.minted_token.uuid,
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
      response =
        provider_request_with_idempotency("/transaction_request.consume", "123", %{
          transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: 100_000 * meta.minted_token.subunit_to_unit,
          metadata: nil,
          token_id: nil,
          address: meta.alice_wallet.address
        })

      consumption_id = response["data"]["id"]
      assert response["success"] == true
      assert response["data"]["status"] == "pending"
      assert response["data"]["transaction_id"] == nil

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
      assert inserted_transfer.amount == 100_000 * meta.minted_token.subunit_to_unit
      assert inserted_transfer.to == meta.alice_wallet.address
      assert inserted_transfer.from == meta.bob_wallet.address
      assert %{} = inserted_transfer.ledger_response

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

    test "sends a websocket expiration event when a consumption expires", meta do
      # bob = test_user
      set_initial_balance(%{
        address: meta.bob_balance.address,
        minted_token: meta.minted_token,
        amount: 1_000_000 * meta.minted_token.subunit_to_unit
      })

      # Create a require_confirmation transaction request that will be consumed soon
      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          minted_token_uuid: meta.minted_token.uuid,
          user_uuid: meta.bob.uuid,
          balance: meta.bob_balance,
          amount: nil,
          require_confirmation: true,

          # The consumption will expire after 1 second.
          consumption_lifetime: 1
        )

      request_topic = "transaction_request:#{transaction_request.id}"

      # Start listening to the channels for the transaction request created above
      Endpoint.subscribe(request_topic)

      # Making the consumption, since we made the request require_confirmation, it will
      # create a pending consumption that will need to be confirmed
      response =
        provider_request_with_idempotency("/transaction_request.consume", "123", %{
          transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: 100_000 * meta.minted_token.subunit_to_unit,
          metadata: nil,
          token_id: nil,
          address: meta.alice_balance.address
        })

      consumption_id = response["data"]["id"]
      assert response["success"] == true
      assert response["data"]["status"] == "pending"

      # The consumption is still valid...
      :timer.sleep(1000)
      # And now it's not!
      # We should receive a transaction_consumption_finalized event.

      # Let's also listen to the consumption channel.
      Endpoint.subscribe(response["data"]["socket_topic"])

      # We trigger the CRON task
      TransactionConsumptionScheduler.expire_all()

      # And we should now receive a finalized failed consumption.
      assert_receive %Phoenix.Socket.Broadcast{
        event: "transaction_consumption_finalized",
        topic: "transaction_request:" <> _,
        payload: payload
      }

      # Ensure the websocket serializer can serialize the payload
      {:socket_push, :text, encoded} =
        WebsocketResponseSerializer.fastlane!(%Broadcast{
          topic: "transaction_request:#{transaction_request.id}",
          event: "transaction_consumption_finalized",
          payload: payload
        })

      decoded = Poison.decode!(encoded)
      assert decoded["success"] == false
      assert decoded["error"]["code"] == "transaction_consumption:expired"

      assert_receive %Phoenix.Socket.Broadcast{
        event: "transaction_consumption_finalized",
        topic: "transaction_consumption:" <> _,
        payload: payload
      }

      # Ensure the websocket serializer can serialize the payload
      {:socket_push, :text, encoded} =
        WebsocketResponseSerializer.fastlane!(%Broadcast{
          topic: "transaction_consumption:#{consumption_id}",
          event: "transaction_consumption_finalized",
          payload: payload
        })

      decoded = Poison.decode!(encoded)
      assert decoded["success"] == false
      assert decoded["error"]["code"] == "transaction_consumption:expired"

      # If we try to approve it now, it will fail since it has already expired.
      response =
        client_request("/me.approve_transaction_consumption", %{
          id: consumption_id
        })

      assert response["success"] == false
      assert response["data"]["code"] == "transaction_consumption:expired"

      # Unsubscribe from all channels
      Endpoint.unsubscribe("transaction_request:#{transaction_request.id}")
      Endpoint.unsubscribe("transaction_consumption:#{consumption_id}")
    end

    test "sends an error when approved without enough funds", meta do
      # Create a require_confirmation transaction request that will be consumed soon
      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          minted_token_uuid: meta.minted_token.uuid,
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
      response =
        provider_request_with_idempotency("/transaction_request.consume", "123", %{
          transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: 100_000 * meta.minted_token.subunit_to_unit,
          metadata: nil,
          token_id: nil,
          address: meta.alice_wallet.address
        })

      consumption_id = response["data"]["id"]
      assert response["success"] == true
      assert response["data"]["status"] == "pending"
      assert response["data"]["transaction_id"] == nil

      # We check that we receive the confirmation request above in the
      # transaction request channel
      assert_receive %Phoenix.Socket.Broadcast{
        event: "transaction_consumption_request",
        topic: "transaction_request:" <> _,
        payload: payload
      }

      # Ensure the websocket serializer can serialize the payload
      {:socket_push, :text, encoded} =
        WebsocketResponseSerializer.fastlane!(%Broadcast{
          topic: "transaction_request:#{transaction_request.id}",
          event: "transaction_consumption_request",
          payload: payload
        })

      decoded = Poison.decode!(encoded)
      assert decoded["success"] == true

      # We need to know once the consumption has been approved, so let's
      # listen to the channel for it
      Endpoint.subscribe("transaction_consumption:#{consumption_id}")

      # Confirm the consumption
      response =
        client_request("/me.approve_transaction_consumption", %{
          id: consumption_id
        })

      assert response["success"] == false
      assert response["data"]["code"] == "transaction:insufficient_funds"

      assert_receive %Phoenix.Socket.Broadcast{
        event: "transaction_consumption_finalized",
        topic: "transaction_consumption:" <> _,
        payload: payload
      }

      {:socket_push, :text, encoded} =
        WebsocketResponseSerializer.fastlane!(%Broadcast{
          topic: "transaction_consumption:#{consumption_id}",
          event: "transaction_consumption_finalized",
          payload: payload
        })

      decoded = Poison.decode!(encoded)
      assert decoded["success"] == false
      assert decoded["error"]["code"] == "transaction:insufficient_funds"
      assert "The specified wallet" <> _ = decoded["error"]["description"]

      # Unsubscribe from all channels
      Endpoint.unsubscribe("transaction_request:#{transaction_request.id}")
      Endpoint.unsubscribe("transaction_consumption:#{consumption_id}")
    end

    test "sends socket confirmation when require_confirmation and rejected", meta do
      mint!(meta.minted_token)

      # Create a require_confirmation transaction request that will be consumed soon
      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          minted_token_uuid: meta.minted_token.uuid,
          account_uuid: meta.account.uuid,
          wallet: meta.account_wallet,
          amount: nil,
          require_confirmation: true,
          max_consumptions: 1
        )

      request_topic = "transaction_request:#{transaction_request.id}"

      # Start listening to the channels for the transaction request created above
      Endpoint.subscribe(request_topic)

      # Making the consumption, since we made the request require_confirmation, it will
      # create a pending consumption that will need to be confirmed
      response =
        provider_request_with_idempotency("/transaction_request.consume", "123", %{
          transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: 100_000 * meta.minted_token.subunit_to_unit,
          metadata: nil,
          token_id: nil,
          provider_user_id: meta.bob.provider_user_id
        })

      consumption_id = response["data"]["id"]
      assert response["success"] == true
      assert response["data"]["status"] == "pending"
      assert response["data"]["transaction_id"] == nil

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

      # We need to know once the consumption has been approved, so let's
      # listen to the channel for it
      Endpoint.subscribe("transaction_consumption:#{consumption_id}")

      # Confirm the consumption
      response =
        provider_request("/transaction_consumption.reject", %{
          id: consumption_id
        })

      assert response["success"] == true
      assert response["data"]["id"] == inserted_consumption.id
      assert response["data"]["status"] == "rejected"
      assert response["data"]["rejected_at"] != nil
      assert response["data"]["approved_at"] == nil
      assert response["data"]["confirmed_at"] == nil

      # Check that a transfer was not inserted
      assert response["data"]["transaction_id"] == nil

      assert_receive %Phoenix.Socket.Broadcast{
        event: "transaction_consumption_finalized",
        topic: "transaction_consumption:" <> _,
        payload:
          %{
            # Ignore content
          }
      }

      # Check that we can consume for real now
      #
      # Making the consumption, since we made the request require_confirmation, it will
      # create a pending consumption that will need to be confirmed
      response =
        provider_request_with_idempotency("/transaction_request.consume", "1234", %{
          transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: 100_000 * meta.minted_token.subunit_to_unit,
          metadata: nil,
          token_id: nil,
          provider_user_id: meta.bob.provider_user_id
        })

      consumption_id = response["data"]["id"]
      assert response["success"] == true
      assert response["data"]["status"] == "pending"
      assert response["data"]["transaction_id"] == nil

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

      # We need to know once the consumption has been approved, so let's
      # listen to the channel for it
      Endpoint.subscribe("transaction_consumption:#{consumption_id}")

      # Confirm the consumption
      response =
        provider_request("/transaction_consumption.approve", %{
          id: consumption_id
        })

      assert response["success"] == true
      assert response["data"]["id"] == inserted_consumption.id
      assert response["data"]["status"] == "confirmed"
      assert response["data"]["confirmed_at"] != nil
      assert response["data"]["approved_at"] != nil
      assert response["data"]["rejected_at"] == nil

      # Check that a transfer was not inserted
      assert response["data"]["transaction_id"] != nil

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
  end

  describe "/me.consume_transaction_request" do
    test "consumes the request and transfers the appropriate amount of tokens", meta do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          minted_token_uuid: meta.minted_token.uuid,
          user_uuid: meta.alice.uuid,
          wallet: meta.alice_wallet,
          amount: 100_000 * meta.minted_token.subunit_to_unit
        )

      set_initial_balance(%{
        address: meta.bob_wallet.address,
        minted_token: meta.minted_token,
        amount: 150_000
      })

      response =
        client_request_with_idempotency("/me.consume_transaction_request", "123", %{
          transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil
        })

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transfer = Repo.get(Transfer, inserted_consumption.transfer_uuid)
      request = TransactionRequest.get(transaction_request.id, preload: [:minted_token])

      assert response == %{
               "success" => true,
               "version" => "1",
               "data" => %{
                 "address" => meta.bob_wallet.address,
                 "amount" => 100_000 * meta.minted_token.subunit_to_unit,
                 "correlation_id" => nil,
                 "id" => inserted_consumption.id,
                 "socket_topic" => "transaction_consumption:#{inserted_consumption.id}",
                 "idempotency_token" => "123",
                 "object" => "transaction_consumption",
                 "status" => "confirmed",
                 "minted_token_id" => meta.minted_token.id,
                 "minted_token" =>
                   meta.minted_token |> MintedTokenSerializer.serialize() |> stringify_keys(),
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

      assert inserted_transfer.amount == 100_000 * meta.minted_token.subunit_to_unit
      assert inserted_transfer.to == meta.alice_wallet.address
      assert inserted_transfer.from == meta.bob_wallet.address
      assert %{} = inserted_transfer.ledger_response
    end

    test "returns same transaction request consumption when idempotency token is the same",
         meta do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          minted_token_uuid: meta.minted_token.uuid,
          user_uuid: meta.alice.uuid,
          wallet: meta.alice_wallet,
          amount: 100_000 * meta.minted_token.subunit_to_unit
        )

      set_initial_balance(%{
        address: meta.bob_wallet.address,
        minted_token: meta.minted_token,
        amount: 150_000
      })

      response =
        client_request_with_idempotency("/me.consume_transaction_request", "1234", %{
          transaction_request_id: transaction_request.id,
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
          transaction_request_id: transaction_request.id,
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
