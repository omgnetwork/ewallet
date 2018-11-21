defmodule AdminAPI.V1.ProviderAuth.TransactionRequestControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.Web.{Date, V1.TokenSerializer, V1.UserSerializer}
  alias EWalletDB.{Account, AccountUser, Repo, TransactionRequest, User}
  alias EWalletConfig.System

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

    test "returns all the transaction_requests", meta do
      response =
        provider_request("/transaction_request.all", %{
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      transfers = [
        meta.tr_1,
        meta.tr_2,
        meta.tr_3
      ]

      assert length(response["data"]["data"]) == length(transfers)

      # All transfers made during setup should exist in the response
      assert Enum.all?(transfers, fn transfer ->
               Enum.any?(response["data"]["data"], fn data ->
                 transfer.id == data["id"]
               end)
             end)
    end

    test "returns all the transaction_requests for a specific status", meta do
      response =
        provider_request("/transaction_request.all", %{
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
               meta.tr_1.id,
               meta.tr_2.id
             ]
    end

    test "returns all transaction_requests filtered", meta do
      response =
        provider_request("/transaction_request.all", %{
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "search_term" => "valid"
        })

      assert response["data"]["data"] |> length() == 2

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.tr_1.id,
               meta.tr_2.id
             ]
    end

    test "returns all transaction_requests sorted and paginated", meta do
      response =
        provider_request("/transaction_request.all", %{
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
               meta.tr_1.id,
               meta.tr_2.id
             ]
    end

    # The endpoint will scope the result to the consumptions associated with the requester,
    # hence the customized factory attrs to make sure the results will be found.
    test_supports_match_any(
      "/transaction_request.all",
      :provider_auth,
      :transaction_request,
      :correlation_id,
      factory_attrs: %{user_uuid: nil, account_uuid: Account.get_master_account().uuid}
    )

    # The endpoint will scope the result to the consumptions associated with the requester,
    # hence the customized factory attrs to make sure the results will be found.
    test_supports_match_all(
      "/transaction_request.all",
      :provider_auth,
      :transaction_request,
      :correlation_id,
      factory_attrs: %{user_uuid: nil, account_uuid: Account.get_master_account().uuid}
    )
  end

  describe "/transaction_request.create" do
    test "creates a transaction request with all the params" do
      account = Account.get_master_account()
      user = get_test_user()
      token = insert(:token)
      wallet = User.get_primary_wallet(user)
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

      response =
        provider_request("/transaction_request.create", %{
          type: "send",
          token_id: token.id,
          correlation_id: "123",
          amount: 1_000,
          address: wallet.address
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
      account = Account.get_master_account()
      user = get_test_user()
      token = insert(:token)
      wallet = User.get_primary_wallet(user)
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

      response =
        provider_request("/transaction_request.create", %{
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
                 "created_at" => Date.to_iso8601(request.inserted_at),
                 "updated_at" => Date.to_iso8601(request.updated_at)
               }
             }
    end

    test "receives an error when the type is invalid" do
      account = Account.get_master_account()
      user = get_test_user()
      token = insert(:token)
      wallet = User.get_primary_wallet(user)
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

      response =
        provider_request("/transaction_request.create", %{
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

    test "receives an error when the address is invalid" do
      token = insert(:token)

      response =
        provider_request("/transaction_request.create", %{
          type: "send",
          token_id: token.id,
          correlation_id: nil,
          amount: nil,
          address: "fake-0000-0000-0000"
        })

      assert response["success"] == false
      assert response["data"]["code"] == "wallet:wallet_not_found"
    end

    test "receives an error when the address does not belong to the user" do
      account = Account.get_master_account()
      token = insert(:token)
      wallet = insert(:wallet)

      response =
        provider_request("/transaction_request.create", %{
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

    test "receives an error when the token ID is not found" do
      account = Account.get_master_account()
      user = get_test_user()
      wallet = User.get_primary_wallet(user)
      {:ok, _} = AccountUser.link(account.uuid, user.uuid, %System{})

      response =
        provider_request("/transaction_request.create", %{
          type: "send",
          token_id: "123",
          correlation_id: nil,
          amount: nil,
          address: wallet.address
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

  describe "/transaction_request.get" do
    test "returns the transaction request" do
      transaction_request = insert(:transaction_request)

      response =
        provider_request("/transaction_request.get", %{
          formatted_id: transaction_request.id
        })

      assert response["success"] == true
      assert response["data"]["id"] == transaction_request.id
    end

    test "returns an error when the request ID is not found" do
      response =
        provider_request("/transaction_request.get", %{
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
