defmodule EWalletAPI.V1.TransactionRequestControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias EWalletDB.{Repo, TransactionRequest, User}
  alias EWallet.Web.{Date, V1.TokenSerializer, V1.UserSerializer}

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
                 "current_consumptions_count" => 0,
                 "created_at" => Date.to_iso8601(request.inserted_at),
                 "updated_at" => Date.to_iso8601(request.updated_at)
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
                 "created_at" => Date.to_iso8601(request.inserted_at),
                 "updated_at" => Date.to_iso8601(request.updated_at)
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
                 "created_at" => Date.to_iso8601(request.inserted_at),
                 "updated_at" => Date.to_iso8601(request.updated_at)
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

    test "receives an error when the address is invalid" do
      token = insert(:token)

      response =
        client_request("/me.create_transaction_request", %{
          type: "send",
          token_id: token.id,
          correlation_id: nil,
          amount: nil,
          address: "fake000000000000"
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "user:wallet_not_found",
                 "description" =>
                   "There is no user wallet corresponding to the provided address.",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test "receives an error when the address does not belong to the user" do
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

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "user:user_wallet_mismatch",
                 "description" => "The provided wallet does not belong to the current user.",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test "receives an error when the token ID is not found" do
      response =
        client_request("/me.create_transaction_request", %{
          type: "send",
          token_id: "123",
          correlation_id: nil,
          amount: nil,
          address: nil
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "token:id_not_found",
                 "description" => "There is no token corresponding to the provided id.",
                 "messages" => nil,
                 "object" => "error"
               }
             }
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

    test "returns an error when the request ID is not found" do
      response =
        client_request("/me.get_transaction_request", %{
          formatted_id: "123"
        })

      assert response["success"] == false
      assert response["data"]["code"] == "unauthorized"
    end
  end
end
