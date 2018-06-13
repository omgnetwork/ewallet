defmodule AdminAPI.V1.TransactionControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWalletDB.User

  setup do
    user = get_test_user()
    wallet_1 = User.get_primary_wallet(user)
    wallet_2 = insert(:wallet)
    wallet_3 = insert(:wallet)
    wallet_4 = insert(:wallet, user: user, identifier: "secondary")

    transfer_1 =
      insert(:transfer, %{
        from_wallet: wallet_1,
        to_wallet: wallet_2,
        status: "confirmed"
      })

    transfer_2 =
      insert(:transfer, %{
        from_wallet: wallet_2,
        to_wallet: wallet_1,
        status: "confirmed"
      })

    transfer_3 =
      insert(:transfer, %{
        from_wallet: wallet_1,
        to_wallet: wallet_3,
        status: "confirmed"
      })

    transfer_4 =
      insert(:transfer, %{
        from_wallet: wallet_1,
        to_wallet: wallet_2,
        status: "pending"
      })

    transfer_5 = insert(:transfer, %{status: "confirmed"})
    transfer_6 = insert(:transfer, %{status: "pending"})

    transfer_7 =
      insert(:transfer, %{
        from_wallet: wallet_4,
        to_wallet: wallet_2,
        status: "confirmed"
      })

    transfer_8 =
      insert(:transfer, %{
        from_wallet: wallet_4,
        to_wallet: wallet_3,
        status: "pending"
      })

    %{
      user: user,
      wallet_1: wallet_1,
      wallet_2: wallet_2,
      wallet_3: wallet_3,
      wallet_4: wallet_4,
      transfer_1: transfer_1,
      transfer_2: transfer_2,
      transfer_3: transfer_3,
      transfer_4: transfer_4,
      transfer_5: transfer_5,
      transfer_6: transfer_6,
      transfer_7: transfer_7,
      transfer_8: transfer_8
    }
  end

  describe "/transaction.all" do
    test "returns all the transactions", meta do
      response =
        provider_request("/transaction.all", %{
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      transfers = [
        meta.transfer_1,
        meta.transfer_2,
        meta.transfer_3,
        meta.transfer_4,
        meta.transfer_5,
        meta.transfer_6,
        meta.transfer_7,
        meta.transfer_8
      ]

      assert length(response["data"]["data"]) == length(transfers)

      # All transfers made during setup should exist in the response
      assert Enum.all?(transfers, fn transfer ->
               Enum.any?(response["data"]["data"], fn data ->
                 transfer.id == data["id"]
               end)
             end)
    end

    test "returns all the transactions for a specific address", meta do
      response =
        provider_request("/transaction.all", %{
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "search_terms" => %{
            "from" => meta.wallet_1.address,
            "to" => meta.wallet_2.address
          }
        })

      assert response["data"]["data"] |> length() == 4

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transfer_1.id,
               meta.transfer_3.id,
               meta.transfer_4.id,
               meta.transfer_7.id
             ]
    end

    test "returns all transactions filtered", meta do
      response =
        provider_request("/transaction.all", %{
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "search_term" => "pending"
        })

      assert response["data"]["data"] |> length() == 3

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transfer_4.id,
               meta.transfer_6.id,
               meta.transfer_8.id
             ]
    end

    test "returns all transactions sorted and paginated", meta do
      response =
        provider_request("/transaction.all", %{
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
               meta.transfer_1.id,
               meta.transfer_2.id
             ]
    end
  end

  describe "/user.get_transactions" do
    test "returns all the transactions for a specific provider_user_id", meta do
      response =
        provider_request("/user.get_transactions", %{
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "provider_user_id" => meta.user.provider_user_id
        })

      assert response["data"]["data"] |> length() == 4

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transfer_1.id,
               meta.transfer_2.id,
               meta.transfer_3.id,
               meta.transfer_4.id
             ]
    end

    test "returns all the transactions for a specific provider_user_id and valid address", meta do
      response =
        provider_request("/user.get_transactions", %{
          "provider_user_id" => meta.user.provider_user_id,
          "address" => meta.wallet_4.address
        })

      assert response["data"]["data"] |> length() == 2

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transfer_7.id,
               meta.transfer_8.id
             ]
    end

    test "returns an 'user:user_wallet_mismatch' error with provider_user_id and invalid address",
         meta do
      response =
        provider_request("/user.get_transactions", %{
          "provider_user_id" => meta.user.provider_user_id,
          "address" => meta.wallet_2.address
        })

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:user_wallet_mismatch"

      assert response["data"]["description"] ==
               "The provided wallet does not belong to the current user"
    end

    test "returns the user's transactions even when different search terms are provided", meta do
      response =
        provider_request("/user.get_transactions", %{
          "provider_user_id" => meta.user.provider_user_id,
          "sort_by" => "created_at",
          "sort_dir" => "desc",
          "search_terms" => %{
            "from" => meta.wallet_2.address,
            "to" => meta.wallet_2.address
          }
        })

      assert response["data"]["data"] |> length() == 4

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transfer_4.id,
               meta.transfer_3.id,
               meta.transfer_2.id,
               meta.transfer_1.id
             ]
    end

    test "returns all transactions filtered", meta do
      response =
        provider_request("/user.get_transactions", %{
          "provider_user_id" => meta.user.provider_user_id,
          "search_terms" => %{"status" => "pending"}
        })

      assert response["data"]["data"] |> length() == 1

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transfer_4.id
             ]
    end

    test "returns all transactions sorted and paginated", meta do
      response =
        provider_request("/user.get_transactions", %{
          "provider_user_id" => meta.user.provider_user_id,
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "per_page" => 2,
          "page" => 1
        })

      assert response["data"]["data"] |> length() == 2

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transfer_1.id,
               meta.transfer_2.id
             ]
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
