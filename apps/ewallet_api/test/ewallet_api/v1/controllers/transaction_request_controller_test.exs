defmodule EWalletAPI.V1.TransactionRequestControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias EWalletDB.{Repo, TransactionRequest, User}

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
          "status" => "valid"
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
          "status" => "valid"
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

  describe "get/2" do

  end
end
