  defmodule EWalletAPI.V1.TransactionConsumptionControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias EWalletDB.{Repo, TransactionRequest, TransactionConsumption, User, Transfer, Account}
  alias EWallet.Web.{Date, V1.MintedTokenSerializer, V1.TransactionRequestSerializer,
                     V1.AccountSerializer}
  alias EWalletAPI.V1.Endpoint

  setup do
    account = Account.get_master_account()
    {:ok, alice}   = :user |> params_for() |> User.insert()
    bob     = get_test_user()

    %{
      account: account,
      minted_token: insert(:minted_token),
      alice: alice,
      bob: bob,
      account_balance: Account.get_primary_balance(account),
      alice_balance: User.get_primary_balance(alice),
      bob_balance: User.get_primary_balance(bob)
    }
  end

  describe "/transaction_request.consume" do
    test "consumes the request and transfers the appropriate amount of tokens", meta do
      transaction_request = insert(:transaction_request,
        type: "receive",
        minted_token_id: meta.minted_token.id,
        user_id: meta.alice.id,
        balance: meta.alice_balance,
        amount: 100_000 * meta.minted_token.subunit_to_unit
      )

      set_initial_balance(%{
        address: meta.bob_balance.address,
        minted_token: meta.minted_token,
        amount: 150_000
      })

      response = provider_request_with_idempotency("/transaction_request.consume", "123", %{
        transaction_request_id: transaction_request.id,
        correlation_id: nil,
        amount: nil,
        address: nil,
        metadata: nil,
        token_id: nil,
        account_id: meta.account.id
      })

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transfer    = Repo.get(Transfer, inserted_consumption.transfer_id)
      request  = TransactionRequest.get(transaction_request.id, preload: [:minted_token])

      assert response == %{
        "success" => true,
        "version" => "1",
        "data" => %{
          "address" => meta.account_balance.address,
          "amount" => 100_000 * meta.minted_token.subunit_to_unit,
          "correlation_id" => nil,
          "id" => inserted_consumption.id,
          "socket_topic" => "transaction_consumption:#{inserted_consumption.id}",
          "idempotency_token" => "123",
          "object" => "transaction_consumption",
          "status" => "confirmed",
          "minted_token_id" => meta.minted_token.friendly_id,
          "minted_token" =>
            meta.minted_token |> MintedTokenSerializer.serialize() |> stringify_keys(),
          "approved" => true,
          "finalized_at" => Date.to_iso8601(inserted_consumption.finalized_at),
          "transaction_request_id" => transaction_request.id,
          "transaction_request" =>
            request |> TransactionRequestSerializer.serialize() |> stringify_keys(),
          "transaction_id" => inserted_transfer.id,
          "transaction" => nil, # not preloaded
          "user_id" => nil,
          "user" => nil,
          "account_id" => meta.account.id,
          "account" => meta.account |> AccountSerializer.serialize() |> stringify_keys(),
          "metadata" => %{},
          "encrypted_metadata" => %{},
          "expiration_date" => nil,
          "expired_at" => nil,
          "created_at" => Date.to_iso8601(inserted_consumption.inserted_at),
          "updated_at" => Date.to_iso8601(inserted_consumption.updated_at)
        }
      }

      assert inserted_transfer.amount == 100_000 * meta.minted_token.subunit_to_unit
      assert inserted_transfer.to == meta.alice_balance.address
      assert inserted_transfer.from == meta.account_balance.address
      assert %{} = inserted_transfer.ledger_response
    end

    test "returns with preload if `embed` attribute is given", meta do
      transaction_request = insert(:transaction_request,
        type: "receive",
        minted_token_id: meta.minted_token.id,
        user_id: meta.alice.id,
        balance: meta.alice_balance,
        amount: 100_000 * meta.minted_token.subunit_to_unit
      )

      set_initial_balance(%{
        address: meta.bob_balance.address,
        minted_token: meta.minted_token,
        amount: 150_000
      })

      response = provider_request_with_idempotency("/transaction_request.consume", "123", %{
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

    test "returns same transaction request consumption when idempotency token is the same", meta do
      transaction_request = insert(:transaction_request,
        type: "receive",
        minted_token_id: meta.minted_token.id,
        user_id: meta.alice.id,
        balance: meta.alice_balance,
        amount: 100_000 * meta.minted_token.subunit_to_unit
      )

      set_initial_balance(%{
        address: meta.bob_balance.address,
        minted_token: meta.minted_token,
        amount: 150_000
      })

      response = provider_request_with_idempotency("/transaction_request.consume", "1234", %{
        transaction_request_id: transaction_request.id,
        correlation_id: nil,
        amount: nil,
        address: nil,
        metadata: nil,
        token_id: nil,
        account_id: meta.account.id
      })

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transfer    = Repo.get(Transfer, inserted_consumption.transfer_id)

      assert response["success"] == true
      assert response["data"]["id"] == inserted_consumption.id

      response = client_request_with_idempotency("/me.consume_transaction_request", "1234", %{
        transaction_request_id: transaction_request.id,
        correlation_id: nil,
        amount: nil,
        address: nil,
        metadata: nil,
        token_id: nil
      })

      inserted_consumption_2 = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transfer_2    = Repo.get(Transfer, inserted_consumption.transfer_id)

      assert response["success"] == true
      assert response["data"]["id"] == inserted_consumption_2.id
      assert inserted_consumption.id == inserted_consumption_2.id
      assert inserted_transfer.id == inserted_transfer_2.id
    end

    test "returns idempotency error if header is not specified" do
      response = client_request("/me.consume_transaction_request", %{
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
          "description" => "The call you made requires the " <>
                           "Idempotency-Token header to prevent duplication.",
          "messages" => nil,
          "object" => "error"
        }
      }
    end

    test "sends socket confirmation when confirmable", meta do
      # Create a confirmable transaction request that will be consumed soon
      transaction_request = insert(:transaction_request,
        type: "send",
        minted_token_id: meta.minted_token.id,
        user_id: meta.alice.id,
        balance: meta.alice_balance,
        amount: nil,
        confirmable: true
      )
      request_topic = "transaction_request:#{transaction_request.id}"

      # Start listening to the channels for the transaction request created above
      Endpoint.subscribe(request_topic)

      # The sender (Alice) needs some tokens, let's fix that
      set_initial_balance(%{
        address: meta.alice_balance.address,
        minted_token: meta.minted_token,
        amount: 150_000
      })

      # Making the consumption, since we made the request confirmable, it will
      # create a pending consumption that will need to be confirmed
      response = provider_request_with_idempotency("/transaction_request.consume", "123", %{
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
        event: "transaction_request_confirmation",
        topic: "transaction_request:" <> _,
        payload: %{
          # Ignore content
        }
      }

      # We need to know once the consumption has been approved, so let's
      # listen to the channel for it
      Endpoint.subscribe("transaction_consumption:#{consumption_id}")

      # Confirm the consumption
      response = provider_request("/transaction_consumption.confirm", %{
        id: consumption_id
      })
      assert response["success"] == true
      assert response["data"]["id"] == inserted_consumption.id
      assert response["data"]["status"] == "confirmed"

      # Check that a transfer was inserted
      inserted_transfer = Repo.get(Transfer, response["data"]["transaction_id"])
      assert inserted_transfer.amount == 100_000 * meta.minted_token.subunit_to_unit
      assert inserted_transfer.to == meta.bob_balance.address
      assert inserted_transfer.from == meta.alice_balance.address
      assert %{} = inserted_transfer.ledger_response

      assert_receive %Phoenix.Socket.Broadcast{
        event: "transaction_consumption_change",
        topic:  "transaction_consumption:" <> _,
        payload: %{
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
      transaction_request = insert(:transaction_request,
        type: "receive",
        minted_token_id: meta.minted_token.id,
        user_id: meta.alice.id,
        balance: meta.alice_balance,
        amount: 100_000 * meta.minted_token.subunit_to_unit
      )

      set_initial_balance(%{
        address: meta.bob_balance.address,
        minted_token: meta.minted_token,
        amount: 150_000
      })

      response = client_request_with_idempotency("/me.consume_transaction_request", "123", %{
        transaction_request_id: transaction_request.id,
        correlation_id: nil,
        amount: nil,
        address: nil,
        metadata: nil,
        token_id: nil
      })

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transfer    = Repo.get(Transfer, inserted_consumption.transfer_id)
      request  = TransactionRequest.get(transaction_request.id, preload: [:minted_token])

      assert response == %{
        "success" => true,
        "version" => "1",
        "data" => %{
          "address" => meta.bob_balance.address,
          "amount" => 100_000 * meta.minted_token.subunit_to_unit,
          "correlation_id" => nil,
          "id" => inserted_consumption.id,
          "socket_topic" => "transaction_consumption:#{inserted_consumption.id}",
          "idempotency_token" => "123",
          "object" => "transaction_consumption",
          "status" => "confirmed",
          "minted_token_id" => meta.minted_token.friendly_id,
          "minted_token" =>
            meta.minted_token |> MintedTokenSerializer.serialize() |> stringify_keys(),
          "transaction_request_id" => transaction_request.id,
          "transaction_request" =>
            request |> TransactionRequestSerializer.serialize() |> stringify_keys(),
          "transaction_id" => inserted_transfer.id,
          "approved" => true,
          "finalized_at" => Date.to_iso8601(inserted_consumption.finalized_at),
          "transaction" => nil, # not preloaded
          "user_id" => meta.bob.id,
          "user" => %{
            "object" => "user",
            "id" => meta.bob.id,
            "provider_user_id" => meta.bob.provider_user_id,
            "username" => meta.bob.username,
            "metadata" => %{
              "first_name" => meta.bob.metadata["first_name"],
              "last_name" => meta.bob.metadata["last_name"]
            },
            "encrypted_metadata" => %{}
          },
          "encrypted_metadata" => %{},
          "expiration_date" => nil,
          "expired_at" => nil,
          "metadata" => %{},
          "account_id" => nil,
          "account" => nil,
          "created_at" => Date.to_iso8601(inserted_consumption.inserted_at),
          "updated_at" => Date.to_iso8601(inserted_consumption.updated_at),
        }
      }

      assert inserted_transfer.amount == 100_000 * meta.minted_token.subunit_to_unit
      assert inserted_transfer.to == meta.alice_balance.address
      assert inserted_transfer.from == meta.bob_balance.address
      assert %{} = inserted_transfer.ledger_response
    end

    test "returns same transaction request consumption when idempotency token is the same", meta do
      transaction_request = insert(:transaction_request,
        type: "receive",
        minted_token_id: meta.minted_token.id,
        user_id: meta.alice.id,
        balance: meta.alice_balance,
        amount: 100_000 * meta.minted_token.subunit_to_unit
      )

      set_initial_balance(%{
        address: meta.bob_balance.address,
        minted_token: meta.minted_token,
        amount: 150_000
      })

      response = client_request_with_idempotency("/me.consume_transaction_request", "1234", %{
        transaction_request_id: transaction_request.id,
        correlation_id: nil,
        amount: nil,
        address: nil,
        metadata: nil,
        token_id: nil
      })

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transfer    = Repo.get(Transfer, inserted_consumption.transfer_id)

      assert response["success"] == true
      assert response["data"]["id"] == inserted_consumption.id

      response = client_request_with_idempotency("/me.consume_transaction_request", "1234", %{
        transaction_request_id: transaction_request.id,
        correlation_id: nil,
        amount: nil,
        address: nil,
        metadata: nil,
        token_id: nil
      })

      inserted_consumption_2 = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transfer_2    = Repo.get(Transfer, inserted_consumption.transfer_id)

      assert response["success"] == true
      assert response["data"]["id"] == inserted_consumption_2.id
      assert inserted_consumption.id == inserted_consumption_2.id
      assert inserted_transfer.id == inserted_transfer_2.id
    end

    test "returns idempotency error if header is not specified" do
      response = client_request("/me.consume_transaction_request", %{
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
          "description" => "The call you made requires the " <>
                           "Idempotency-Token header to prevent duplication.",
          "messages" => nil,
          "object" => "error"
        }
      }
    end
  end
end
