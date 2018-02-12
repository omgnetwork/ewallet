defmodule EWalletAPI.V1.TransactionRequestControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias EWalletDB.{Repo, TransactionRequest, TransactionRequestConsumption, User, Transfer}

  describe "create/2" do
    test "creates a transaction request with all the params" do
      user         = get_test_user()
      minted_token = insert(:minted_token)
      balance      = User.get_primary_balance(user)

      response = client_request("/me.create_transaction_request", %{
        type: "send",
        token_id: minted_token.friendly_id,
        correlation_id: "123",
        amount: 1_000,
        address: balance.address,
      })

      request = TransactionRequest |> Repo.all() |> Enum.at(0)

      assert response == %{
        "success" => true,
        "version" => "1",
        "data" => %{
          "object" => "transaction_request",
          "amount" => 1_000,
          "address" => balance.address,
          "correlation_id" => "123",
          "id" => request.id,
          "token_id" => minted_token.friendly_id,
          "type" => "send",
          "status" => "pending"
        }
      }
    end

    test "creates a transaction request with the minimum params" do
      user         = get_test_user()
      minted_token = insert(:minted_token)
      balance      = User.get_primary_balance(user)

      response = client_request("/me.create_transaction_request", %{
        type: "send",
        token_id: minted_token.friendly_id,
        correlation_id: nil,
        amount: nil,
        address: nil,
      })

      request = TransactionRequest |> Repo.all() |> Enum.at(0)

      assert response == %{
        "success" => true,
        "version" => "1",
        "data" => %{
          "object" => "transaction_request",
          "amount" => nil,
          "address" => balance.address,
          "correlation_id" => nil,
          "id" => request.id,
          "token_id" => minted_token.friendly_id,
          "type" => "send",
          "status" => "pending"
        }
      }
    end

    test "receives an error when the type is invalid" do
      minted_token = insert(:minted_token)

      response = client_request("/me.create_transaction_request", %{
        type: "fake",
        token_id: minted_token.friendly_id,
        correlation_id: nil,
        amount: nil,
        address: nil,
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

    test "receives an error when the address is invalid" do
      minted_token = insert(:minted_token)

      response = client_request("/me.create_transaction_request", %{
        type: "send",
        token_id: minted_token.friendly_id,
        correlation_id: nil,
        amount: nil,
        address: "fake",
      })

      assert response == %{
        "success" => false,
        "version" => "1",
        "data" => %{
          "code" => "user:balance_not_found",
          "description" => "There is no balance corresponding to the provided address",
          "messages" => nil,
          "object" => "error"
        }
      }
    end

    test "receives an error when the address does not belong to the user" do
      minted_token = insert(:minted_token)
      balance      = insert(:balance)

      response = client_request("/me.create_transaction_request", %{
        type: "send",
        token_id: minted_token.friendly_id,
        correlation_id: nil,
        amount: nil,
        address: balance.address,
      })

      assert response == %{
        "success" => false,
        "version" => "1",
        "data" => %{
          "code" => "user:user_balance_mismatch",
          "description" => "The provided balance does not belong to the current user",
          "messages" => nil,
          "object" => "error"
        }
      }
    end

    test "receives an error when the token ID is not found" do
      response = client_request("/me.create_transaction_request", %{
        type: "send",
        token_id: "123",
        correlation_id: nil,
        amount: nil,
        address: nil,
      })

      assert response == %{
        "success" => false,
        "version" => "1",
        "data" => %{
          "code" => "user:minted_token_not_found",
          "description" => "There is no minted token matching the provided token_id.",
          "messages" => nil,
          "object" => "error"
        }
      }
    end
  end

  describe "consume/2" do
    # No idempotency?
    # with transaction request created through API
    # with address / without address in request
    # with amount / without amount in request
    test "" do
      minted_token        = insert(:minted_token)
      {:ok, alice}        = User.insert(%{
        username: "alice",
        provider_user_id: "alice",
        metadata: %{}
      })   # receiver
      bob                 = get_test_user() # sender
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
        metadata: nil
      })

      inserted_consumption = TransactionRequestConsumption |> Repo.all() |> Enum.at(0)
      inserted_transfer    = Repo.get(Transfer, inserted_consumption.transfer_id)

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
          "token_id" => minted_token.friendly_id,
          "transaction_request_id" => transaction_request.id,
          "transfer_id" => inserted_transfer.id,
          "user_id" => bob.id
        }
      }

      assert inserted_transfer.amount == 100_000 * minted_token.subunit_to_unit
      assert inserted_transfer.to == alice_balance.address
      assert inserted_transfer.from == bob_balance.address
      assert %{} = inserted_transfer.ledger_response
    end
  end
end
