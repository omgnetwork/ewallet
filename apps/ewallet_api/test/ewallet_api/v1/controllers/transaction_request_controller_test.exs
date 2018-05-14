defmodule EWalletAPI.V1.TransactionRequestControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias EWalletDB.{Repo, TransactionRequest, User, Account}
  alias EWallet.Web.{Date, V1.MintedTokenSerializer, V1.UserSerializer}

  describe "/transaction_request.create" do
    test "creates a transaction request with all the params" do
      user = get_test_user()
      minted_token = insert(:minted_token)
      balance = User.get_primary_balance(user)

      response =
        provider_request("/transaction_request.create", %{
          type: "send",
          token_id: minted_token.id,
          correlation_id: "123",
          amount: 1_000,
          address: balance.address
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
                 "socket_topic" => "transaction_request:#{request.id}",
                 "minted_token_id" => minted_token.id,
                 "minted_token" =>
                   minted_token |> MintedTokenSerializer.serialize() |> stringify_keys(),
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
                 "created_at" => Date.to_iso8601(request.inserted_at),
                 "updated_at" => Date.to_iso8601(request.updated_at)
               }
             }
    end

    test "creates a transaction request with the minimum params" do
      user = get_test_user()
      minted_token = insert(:minted_token)
      balance = User.get_primary_balance(user)

      response =
        provider_request("/transaction_request.create", %{
          type: "send",
          token_id: minted_token.id,
          correlation_id: nil,
          amount: nil,
          address: balance.address
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
                 "socket_topic" => "transaction_request:#{request.id}",
                 "minted_token_id" => minted_token.id,
                 "minted_token" =>
                   minted_token |> MintedTokenSerializer.serialize() |> stringify_keys(),
                 "type" => "send",
                 "status" => "valid",
                 "user_id" => user.id,
                 "user" => user |> UserSerializer.serialize() |> stringify_keys(),
                 "account_id" => nil,
                 "account" => nil,
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
                 "created_at" => Date.to_iso8601(request.inserted_at),
                 "updated_at" => Date.to_iso8601(request.updated_at)
               }
             }
    end

    test "receives an error when the type is invalid" do
      minted_token = insert(:minted_token)
      user = get_test_user()
      balance = User.get_primary_balance(user)

      response =
        provider_request("/transaction_request.create", %{
          type: "fake",
          token_id: minted_token.id,
          correlation_id: nil,
          amount: nil,
          address: balance.address
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "client:invalid_parameter",
                 "description" => "Invalid parameter provided `type` is invalid.",
                 "messages" => %{"type" => ["inclusion"]},
                 "object" => "error"
               }
             }
    end

    test "receives an error when the address is invalid" do
      minted_token = insert(:minted_token)

      response =
        provider_request("/transaction_request.create", %{
          type: "send",
          token_id: minted_token.id,
          correlation_id: nil,
          amount: nil,
          address: "fake"
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
      account = Account.get_master_account()
      minted_token = insert(:minted_token)
      balance = insert(:balance)

      response =
        provider_request("/transaction_request.create", %{
          type: "send",
          token_id: minted_token.id,
          correlation_id: nil,
          amount: nil,
          account_id: account.id,
          address: balance.address
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "account:account_balance_mismatch",
                 "description" => "The provided balance does not belong to the given account",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test "receives an error when the token ID is not found" do
      balance = insert(:balance)

      response =
        provider_request("/transaction_request.create", %{
          type: "send",
          token_id: "123",
          correlation_id: nil,
          amount: nil,
          address: balance.address
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "minted_token:minted_token_not_found",
                 "description" => "There is no minted token matching the provided token_id.",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end
  end

  describe "/me.create_transaction_request" do
    test "creates a transaction request with all the params" do
      user = get_test_user()
      minted_token = insert(:minted_token)
      balance = User.get_primary_balance(user)

      response =
        client_request("/me.create_transaction_request", %{
          type: "send",
          token_id: minted_token.id,
          correlation_id: "123",
          amount: 1_000,
          address: balance.address,
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
                 "address" => balance.address,
                 "correlation_id" => "123",
                 "id" => request.id,
                 "socket_topic" => "transaction_request:#{request.id}",
                 "minted_token_id" => minted_token.id,
                 "minted_token" =>
                   minted_token |> MintedTokenSerializer.serialize() |> stringify_keys(),
                 "type" => "send",
                 "status" => "valid",
                 "user_id" => user.id,
                 "user" => user |> UserSerializer.serialize() |> stringify_keys(),
                 "account_id" => nil,
                 "account" => nil,
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
      minted_token = insert(:minted_token)
      balance = User.get_primary_balance(user)

      response =
        client_request("/me.create_transaction_request", %{
          type: "send",
          token_id: minted_token.id,
          correlation_id: nil,
          amount: nil,
          address: nil
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
                 "socket_topic" => "transaction_request:#{request.id}",
                 "minted_token_id" => minted_token.id,
                 "minted_token" =>
                   minted_token |> MintedTokenSerializer.serialize() |> stringify_keys(),
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
                 "created_at" => Date.to_iso8601(request.inserted_at),
                 "updated_at" => Date.to_iso8601(request.updated_at)
               }
             }
    end

    test "receives an error when the type is invalid" do
      minted_token = insert(:minted_token)

      response =
        client_request("/me.create_transaction_request", %{
          type: "fake",
          token_id: minted_token.id,
          correlation_id: nil,
          amount: nil,
          address: nil
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "client:invalid_parameter",
                 "description" => "Invalid parameter provided `type` is invalid.",
                 "messages" => %{"type" => ["inclusion"]},
                 "object" => "error"
               }
             }
    end

    test "receives an error when the address is invalid" do
      minted_token = insert(:minted_token)

      response =
        client_request("/me.create_transaction_request", %{
          type: "send",
          token_id: minted_token.id,
          correlation_id: nil,
          amount: nil,
          address: "fake"
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
      balance = insert(:balance)

      response =
        client_request("/me.create_transaction_request", %{
          type: "send",
          token_id: minted_token.id,
          correlation_id: nil,
          amount: nil,
          address: balance.address
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
                 "code" => "minted_token:minted_token_not_found",
                 "description" => "There is no minted token matching the provided token_id.",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end
  end

  describe "/transaction_request.get" do
    test "returns the transaction request" do
      transaction_request = insert(:transaction_request)

      response =
        provider_request("/transaction_request.get", %{
          id: transaction_request.id
        })

      assert response["success"] == true
      assert response["data"]["id"] == transaction_request.id
    end

    test "returns an error when the request ID is not found" do
      response =
        provider_request("/transaction_request.get", %{
          id: "123"
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "transaction_request:transaction_request_not_found",
                 "description" =>
                   "There is no transaction request corresponding to the provided address",
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
          id: transaction_request.id
        })

      assert response["success"] == true
      assert response["data"]["id"] == transaction_request.id
    end

    test "returns an error when the request ID is not found" do
      response =
        client_request("/me.get_transaction_request", %{
          id: "123"
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "transaction_request:transaction_request_not_found",
                 "description" =>
                   "There is no transaction request corresponding to the provided address",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end
  end
end
