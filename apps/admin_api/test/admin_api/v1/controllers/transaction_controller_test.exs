defmodule AdminAPI.V1.TransactionControllerTest do
  use AdminAPI.ConnCase, async: true

  describe "/transaction.all" do
    test "returns a list of transactions and pagination data" do
      response = user_request("/transaction.all")

      # Asserts return data
      assert response["success"]
      assert response["data"]["object"] == "list"
      assert is_list(response["data"]["data"])

      # Asserts pagination data
      pagination = response["data"]["pagination"]
      assert is_integer(pagination["per_page"])
      assert is_integer(pagination["current_page"])
      assert is_boolean(pagination["is_last_page"])
      assert is_boolean(pagination["is_first_page"])
    end

    test "returns a list of transactions according to search_term, sort_by and sort_direction" do
      wallet1 = insert(:wallet, address: "ABC1")
      wallet2 = insert(:wallet, address: "ABC3")
      wallet3 = insert(:wallet, address: "ABC2")
      wallet4 = insert(:wallet, address: "XYZ1")

      insert(:transfer, %{from_wallet: wallet1})
      insert(:transfer, %{from_wallet: wallet2})
      insert(:transfer, %{from_wallet: wallet3})
      insert(:transfer, %{from_wallet: wallet4})

      attrs = %{
        # Search is case-insensitive
        "search_term" => "aBc",
        "sort_by" => "from",
        "sort_dir" => "desc"
      }

      response = user_request("/transaction.all", attrs)
      transactions = response["data"]["data"]

      assert response["success"]
      assert Enum.count(transactions) == 3
      assert Enum.at(transactions, 0)["from"]["address"] == "ABC3"
      assert Enum.at(transactions, 1)["from"]["address"] == "ABC2"
      assert Enum.at(transactions, 2)["from"]["address"] == "ABC1"
    end
  end

  describe "/transaction.get" do
    test "returns an transaction by the given transaction's ID" do
      transactions = insert_list(3, :transfer)
      # Pick the 2nd inserted transaction
      target = Enum.at(transactions, 1)
      response = user_request("/transaction.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "transaction"
      assert response["data"]["id"] == target.id
    end

    test "returns 'transaction:id_not_found' if the given ID was not found" do
      response = user_request("/transaction.get", %{"id" => "tfr_12345678901234567890123456"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "transaction:id_not_found"

      assert response["data"]["description"] ==
               "There is no transaction corresponding to the provided id"
    end

    test "returns 'transaction:id_not_found' if the given ID format is invalid" do
      response = user_request("/transaction.get", %{"id" => "not_valid_id"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "transaction:id_not_found"

      assert response["data"]["description"] ==
               "There is no transaction corresponding to the provided id"
    end
  end

  describe "/transaction.create" do
    test "creates a transaction when all params are valid" do
      token = insert(:token)
      mint!(token)

      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)

      set_initial_balance(%{
        address: wallet_1.address,
        token: token,
        amount: 2_000_000
      })

      response =
        user_request_with_idempotency("/transaction.create", "123", %{
          "from_address" => wallet_1.address,
          "to_address" => wallet_2.address,
          "token_id" => token.id,
          "amount" => 1_000_000
        })

      assert response["success"]
      assert response["data"]["object"] == "transaction"
      assert response["data"]["status"] == "confirmed"
    end

    test "returns transaction:insufficient_funds when the sending address does not have enough funds" do
      token = insert(:token)
      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)

      response =
        user_request_with_idempotency("/transaction.create", "123", %{
          "from_address" => wallet_1.address,
          "to_address" => wallet_2.address,
          "token_id" => token.id,
          "amount" => 1_000_000
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "transaction:insufficient_funds",
               "description" =>
                 "The specified wallet (#{wallet_1.address}) does not contain enough funds. Available: 0.0 #{
                   token.id
                 } - Attempted debit: 10000.0 #{token.id}",
               "messages" => nil,
               "object" => "error"
             }
    end

    test "returns client:no_idempotency_token_provided when idempotency token is not given" do
      token = insert(:token)
      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)

      response =
        user_request("/transaction.create", %{
          "from_address" => wallet_1.address,
          "to_address" => wallet_2.address,
          "token_id" => token.id,
          "amount" => 1_000_000
        })

      assert response["success"] == false

      assert response["data"] == %{
               "messages" => nil,
               "object" => "error",
               "code" => "client:no_idempotency_token_provided",
               "description" =>
                 "The call you made requires the Idempotency-Token header to prevent duplication."
             }
    end

    test "returns user:to_address_not_found when from_address does not exist" do
      token = insert(:token)
      mint!(token)

      wallet_1 = insert(:wallet)

      set_initial_balance(%{
        address: wallet_1.address,
        token: token,
        amount: 2_000_000
      })

      response =
        user_request_with_idempotency("/transaction.create", "123", %{
          "from_address" => wallet_1.address,
          "to_address" => "fake",
          "token_id" => token.id,
          "amount" => 1_000_000
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "user:to_address_not_found",
               "description" => "No wallet found for the provided to_address.",
               "messages" => nil,
               "object" => "error"
             }
    end

    test "returns user:from_address_not_found when to_address does not exist" do
      token = insert(:token)
      wallet_2 = insert(:wallet)

      response =
        user_request_with_idempotency("/transaction.create", "123", %{
          "from_address" => "fake",
          "to_address" => wallet_2.address,
          "token_id" => token.id,
          "amount" => 1_000_000
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "user:from_address_not_found",
               "description" => "No wallet found for the provided from_address.",
               "messages" => nil,
               "object" => "error"
             }
    end

    test "returns token:token_not_found when token_id does not exist" do
      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)

      response =
        user_request_with_idempotency("/transaction.create", "123", %{
          "from_address" => wallet_1.address,
          "to_address" => wallet_2.address,
          "token_id" => "fake",
          "amount" => 1_000_000
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "token:token_not_found",
               "description" => "There is no token matching the provided token_id.",
               "messages" => nil,
               "object" => "error"
             }
    end

    test "returns : when amount is invalid" do
      token = insert(:token)
      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)

      response =
        user_request_with_idempotency("/transaction.create", "123", %{
          "from_address" => wallet_1.address,
          "to_address" => wallet_2.address,
          "token_id" => token.id,
          "amount" => "fake"
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "client:invalid_parameter",
               "description" => "Invalid parameter provided",
               "messages" => nil,
               "object" => "error"
             }
    end
  end
end
