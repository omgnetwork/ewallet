defmodule EWalletAPI.V1.TransactionRequestControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias EWalletDB.{Repo, TransactionRequest}

  describe "create/2" do
    test "creates a transaction request with all the params" do
      minted_token = insert(:minted_token)
      _balance     = insert(:balance, address: "1234")

      response = client_request("/transaction_request.create", %{
        type: "send",
        token_id: minted_token.friendly_id,
        correlation_id: "123",
        amount: 1_000,
        address: "1234",
      })

      request = TransactionRequest |> Repo.all() |> Enum.at(0)

      assert response == %{
        "success" => true,
        "version" => "1",
        "data" => %{
          "object" => "transaction_request",
          "amount" => 1_000,
          "address" => "1234",
          "correlation_id" => "123",
          "id" => request.id,
          "token_id" => minted_token.friendly_id,
          "type" => "send",
          "status" => "pending"
        }
      }
    end

    test "creates a transaction request with the minimum params" do
      minted_token = insert(:minted_token)

      response = client_request("/transaction_request.create", %{
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
          "address" => nil,
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

      response = client_request("/transaction_request.create", %{
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

    test "receives an error when the token ID is not found" do
      response = client_request("/transaction_request.create", %{
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
end
