defmodule EWalletAPI.V1.TransactionRequestConsumptionControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias EWalletDB.{Repo, TransactionRequestConsumption, User, Transfer, Account}
  alias EWallet.Web.Date

  describe "/transaction_request.consume" do
    test "consumes the request and transfers the appropriate amount of tokens" do
      account             = Account.get_master_account()
      minted_token        = insert(:minted_token)
      {:ok, alice}        = :user |> params_for() |> User.insert()
      bob                 = get_test_user()
      account_balance     = Account.get_primary_balance(account)
      alice_balance       = User.get_primary_balance(alice)
      bob_balance         = User.get_primary_balance(bob)

      transaction_request = insert(:transaction_request,
        type: "receive",
        minted_token_id: minted_token.id,
        user_id: alice.id,
        balance: alice_balance,
        amount: 100_000 * minted_token.subunit_to_unit
      )

      set_initial_balance(%{
        address: bob_balance.address,
        minted_token: minted_token,
        amount: 150_000
      })

      response = provider_request_with_idempotency("/transaction_request.consume", "123", %{
        transaction_request_id: transaction_request.id,
        correlation_id: nil,
        amount: nil,
        address: nil,
        metadata: nil,
        token_id: nil,
        account_id: account.id
      })

      inserted_consumption = TransactionRequestConsumption |> Repo.all() |> Enum.at(0)
      inserted_transfer    = Repo.get(Transfer, inserted_consumption.transfer_id)
      transaction_request  = Repo.preload(transaction_request, :minted_token)

      assert response == %{
        "success" => true,
        "version" => "1",
        "data" => %{
          "address" => account_balance.address,
          "amount" => 100_000 * minted_token.subunit_to_unit,
          "correlation_id" => nil,
          "id" => inserted_consumption.id,
          "idempotency_token" => "123",
          "object" => "transaction_request_consumption",
          "status" => "confirmed",
          "minted_token_id" => minted_token.friendly_id,
          "minted_token" => %{
            "id" => minted_token.friendly_id,
            "name" => minted_token.name,
            "object" => "minted_token",
            "subunit_to_unit" => minted_token.subunit_to_unit,
            "symbol" => minted_token.symbol,
            "metadata" => %{},
            "encrypted_metadata" => %{},
            "created_at" => Date.to_iso8601(minted_token.inserted_at),
            "updated_at" => Date.to_iso8601(minted_token.updated_at)
          },
          "transaction_request_id" => transaction_request.id,
          "transaction_request" => %{
            "object" => "transaction_request",
            "id" => transaction_request.id,
            "correlation_id" => transaction_request.correlation_id,
            "type" => transaction_request.type,
            "status" => transaction_request.status,
            "user_id" => transaction_request.user_id,
            "account_id" => transaction_request.account_id,
            "address" => transaction_request.balance.address,
            "amount" => transaction_request.amount,
            "minted_token_id" => transaction_request.minted_token.friendly_id,
            "minted_token" => %{
              "object" => "minted_token",
              "id" => transaction_request.minted_token.friendly_id,
              "symbol" => transaction_request.minted_token.symbol,
              "name" => transaction_request.minted_token.name,
              "subunit_to_unit" => transaction_request.minted_token.subunit_to_unit,
              "metadata" => transaction_request.minted_token.metadata,
              "encrypted_metadata" => transaction_request.minted_token.encrypted_metadata,
              "created_at" => Date.to_iso8601(transaction_request.minted_token.inserted_at),
              "updated_at" => Date.to_iso8601(transaction_request.minted_token.updated_at)
            },
            "created_at" => Date.to_iso8601(transaction_request.inserted_at),
            "updated_at" => Date.to_iso8601(transaction_request.updated_at),
          },
          "transaction_id" => inserted_transfer.id,
          "transaction" => nil, # not preloaded
          "user_id" => nil,
          "user" => nil,
          "account_id" => account.id,
          "account" => nil,
          "created_at" => Date.to_iso8601(inserted_consumption.inserted_at),
          "updated_at" => Date.to_iso8601(inserted_consumption.updated_at)
        }
      }

      assert inserted_transfer.amount == 100_000 * minted_token.subunit_to_unit
      assert inserted_transfer.to == alice_balance.address
      assert inserted_transfer.from == account_balance.address
      assert %{} = inserted_transfer.ledger_response
    end

    test "returns with preload if `embed` attribute is given" do
      account             = Account.get_master_account()
      minted_token        = insert(:minted_token)
      {:ok, alice}        = :user |> params_for() |> User.insert()
      bob                 = get_test_user()
      alice_balance       = User.get_primary_balance(alice)
      bob_balance         = User.get_primary_balance(bob)

      transaction_request = insert(:transaction_request,
        type: "receive",
        minted_token_id: minted_token.id,
        user_id: alice.id,
        balance: alice_balance,
        amount: 100_000 * minted_token.subunit_to_unit
      )

      set_initial_balance(%{
        address: bob_balance.address,
        minted_token: minted_token,
        amount: 150_000
      })

      response = provider_request_with_idempotency("/transaction_request.consume", "123", %{
        transaction_request_id: transaction_request.id,
        correlation_id: nil,
        amount: nil,
        address: nil,
        metadata: nil,
        token_id: nil,
        account_id: account.id,
        embed: ["account"]
      })

      assert response["data"]["account"] != nil
    end

    test "returns same transaction request consumption when idempotency token is the same" do
      account             = Account.get_master_account()
      minted_token        = insert(:minted_token)
      {:ok, alice}        = :user |> params_for() |> User.insert()
      bob                 = get_test_user()
      alice_balance       = User.get_primary_balance(alice)
      bob_balance         = User.get_primary_balance(bob)

      transaction_request = insert(:transaction_request,
        type: "receive",
        minted_token_id: minted_token.id,
        user_id: alice.id,
        balance: alice_balance,
        amount: 100_000 * minted_token.subunit_to_unit
      )

      set_initial_balance(%{
        address: bob_balance.address,
        minted_token: minted_token,
        amount: 150_000
      })

      response = provider_request_with_idempotency("/transaction_request.consume", "1234", %{
        transaction_request_id: transaction_request.id,
        correlation_id: nil,
        amount: nil,
        address: nil,
        metadata: nil,
        token_id: nil,
        account_id: account.id
      })

      inserted_consumption = TransactionRequestConsumption |> Repo.all() |> Enum.at(0)
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

      inserted_consumption_2 = TransactionRequestConsumption |> Repo.all() |> Enum.at(0)
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

  describe "/me.consume_transaction_request" do
    test "consumes the request and transfers the appropriate amount of tokens" do
      minted_token        = insert(:minted_token)
      {:ok, alice}        = :user |> params_for() |> User.insert()
      bob                 = get_test_user()
      alice_balance       = User.get_primary_balance(alice)
      bob_balance         = User.get_primary_balance(bob)

      transaction_request = insert(:transaction_request,
        type: "receive",
        minted_token_id: minted_token.id,
        user_id: alice.id,
        balance: alice_balance,
        amount: 100_000 * minted_token.subunit_to_unit
      )

      set_initial_balance(%{
        address: bob_balance.address,
        minted_token: minted_token,
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

      inserted_consumption = TransactionRequestConsumption |> Repo.all() |> Enum.at(0)
      inserted_transfer    = Repo.get(Transfer, inserted_consumption.transfer_id)
      transaction_request  = Repo.preload(transaction_request, :minted_token)

      assert response == %{
        "success" => true,
        "version" => "1",
        "data" => %{
          "address" => bob_balance.address,
          "amount" => 100_000 * minted_token.subunit_to_unit,
          "correlation_id" => nil,
          "id" => inserted_consumption.id,
          "idempotency_token" => "123",
          "object" => "transaction_request_consumption",
          "status" => "confirmed",
          "minted_token_id" => minted_token.friendly_id,
          "minted_token" => %{
            "id" => minted_token.friendly_id,
            "name" => minted_token.name,
            "object" => "minted_token",
            "subunit_to_unit" => minted_token.subunit_to_unit,
            "symbol" => minted_token.symbol,
            "metadata" => %{},
            "encrypted_metadata" => %{},
            "created_at" => Date.to_iso8601(minted_token.inserted_at),
            "updated_at" => Date.to_iso8601(minted_token.updated_at)
          },
          "transaction_request_id" => transaction_request.id,
          "transaction_request" => %{
            "object" => "transaction_request",
            "id" => transaction_request.id,
            "correlation_id" => transaction_request.correlation_id,
            "type" => transaction_request.type,
            "status" => transaction_request.status,
            "user_id" => transaction_request.user_id,
            "account_id" => transaction_request.account_id,
            "address" => transaction_request.balance_address,
            "amount" => transaction_request.amount,
            "minted_token_id" => transaction_request.minted_token.friendly_id,
            "minted_token" => %{
              "object" => "minted_token",
              "id" => transaction_request.minted_token.friendly_id,
              "symbol" => transaction_request.minted_token.symbol,
              "name" => transaction_request.minted_token.name,
              "subunit_to_unit" => transaction_request.minted_token.subunit_to_unit,
              "metadata" => transaction_request.minted_token.metadata,
              "encrypted_metadata" => transaction_request.minted_token.encrypted_metadata,
              "created_at" => Date.to_iso8601(transaction_request.minted_token.inserted_at),
              "updated_at" => Date.to_iso8601(transaction_request.minted_token.updated_at)
            },
            "created_at" => Date.to_iso8601(transaction_request.inserted_at),
            "updated_at" => Date.to_iso8601(transaction_request.updated_at),
          },
          "transaction_id" => inserted_transfer.id,
          "transaction" => nil, # not preloaded
          "user_id" => bob.id,
          "user" => %{
            "object" => "user",
            "id" => bob.id,
            "provider_user_id" => bob.provider_user_id,
            "username" => bob.username,
            "metadata" => %{
              "first_name" => bob.metadata["first_name"],
              "last_name" => bob.metadata["last_name"]
            },
            "encrypted_metadata" => %{}
          },
          "account_id" => nil,
          "account" => nil,
          "created_at" => Date.to_iso8601(inserted_consumption.inserted_at),
          "updated_at" => Date.to_iso8601(inserted_consumption.updated_at),
        }
      }

      assert inserted_transfer.amount == 100_000 * minted_token.subunit_to_unit
      assert inserted_transfer.to == alice_balance.address
      assert inserted_transfer.from == bob_balance.address
      assert %{} = inserted_transfer.ledger_response
    end

    test "returns same transaction request consumption when idempotency token is the same" do
      minted_token        = insert(:minted_token)
      {:ok, alice}        = :user |> params_for() |> User.insert()
      bob                 = get_test_user()
      alice_balance       = User.get_primary_balance(alice)
      bob_balance         = User.get_primary_balance(bob)

      transaction_request = insert(:transaction_request,
        type: "receive",
        minted_token_id: minted_token.id,
        user_id: alice.id,
        balance: alice_balance,
        amount: 100_000 * minted_token.subunit_to_unit
      )

      set_initial_balance(%{
        address: bob_balance.address,
        minted_token: minted_token,
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

      inserted_consumption = TransactionRequestConsumption |> Repo.all() |> Enum.at(0)
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

      inserted_consumption_2 = TransactionRequestConsumption |> Repo.all() |> Enum.at(0)
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
