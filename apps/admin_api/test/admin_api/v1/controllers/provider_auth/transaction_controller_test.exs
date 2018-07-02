defmodule AdminAPI.V1.ProviderAuth.TransactionControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWalletDB.{User, Account}

  # credo:disable-for-next-line
  setup do
    user = get_test_user()
    wallet_1 = User.get_primary_wallet(user)
    wallet_2 = insert(:wallet)
    wallet_3 = insert(:wallet)
    wallet_4 = insert(:wallet, user: user, identifier: "secondary")

    transaction_1 =
      insert(:transaction, %{
        from_wallet: wallet_1,
        to_wallet: wallet_2,
        status: "confirmed"
      })

    transaction_2 =
      insert(:transaction, %{
        from_wallet: wallet_2,
        to_wallet: wallet_1,
        status: "confirmed"
      })

    transaction_3 =
      insert(:transaction, %{
        from_wallet: wallet_1,
        to_wallet: wallet_3,
        status: "confirmed"
      })

    transaction_4 =
      insert(:transaction, %{
        from_wallet: wallet_1,
        to_wallet: wallet_2,
        status: "pending"
      })

    transaction_5 = insert(:transaction, %{status: "confirmed"})
    transaction_6 = insert(:transaction, %{status: "pending"})

    transaction_7 =
      insert(:transaction, %{
        from_wallet: wallet_4,
        to_wallet: wallet_2,
        status: "confirmed"
      })

    transaction_8 =
      insert(:transaction, %{
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
      transaction_1: transaction_1,
      transaction_2: transaction_2,
      transaction_3: transaction_3,
      transaction_4: transaction_4,
      transaction_5: transaction_5,
      transaction_6: transaction_6,
      transaction_7: transaction_7,
      transaction_8: transaction_8
    }
  end

  describe "/transaction.all" do
    test "returns all the transactions", meta do
      response =
        provider_request("/transaction.all", %{
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      transactions = [
        meta.transaction_1,
        meta.transaction_2,
        meta.transaction_3,
        meta.transaction_4,
        meta.transaction_5,
        meta.transaction_6,
        meta.transaction_7,
        meta.transaction_8
      ]

      assert length(response["data"]["data"]) == length(transactions)

      # All transactions made during setup should exist in the response
      assert Enum.all?(transactions, fn transaction ->
               Enum.any?(response["data"]["data"], fn data ->
                 transaction.id == data["id"]
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
               meta.transaction_1.id,
               meta.transaction_3.id,
               meta.transaction_4.id,
               meta.transaction_7.id
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
               meta.transaction_4.id,
               meta.transaction_6.id,
               meta.transaction_8.id
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
               meta.transaction_1.id,
               meta.transaction_2.id
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
               meta.transaction_1.id,
               meta.transaction_2.id,
               meta.transaction_3.id,
               meta.transaction_4.id
             ]
    end

    test "returns all the transactions for a specific provider_user_id and valid address", meta do
      response =
        provider_request("/user.get_transactions", %{
          "provider_user_id" => meta.user.provider_user_id,
          "address" => meta.wallet_4.address
        })

      assert response["data"]["data"] |> length() == 2

      ids = Enum.map(response["data"]["data"], fn t -> t["id"] end)
      assert length(ids) == 2
      assert Enum.member?(ids, meta.transaction_7.id)
      assert Enum.member?(ids, meta.transaction_8.id)
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
               meta.transaction_4.id,
               meta.transaction_3.id,
               meta.transaction_2.id,
               meta.transaction_1.id
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
               meta.transaction_4.id
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
               meta.transaction_1.id,
               meta.transaction_2.id
             ]
    end
  end

  describe "/transaction.get" do
    test "returns an transaction by the given transaction's ID" do
      transactions = insert_list(3, :transaction)
      # Pick the 2nd inserted transaction
      target = Enum.at(transactions, 1)
      response = provider_request("/transaction.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "transaction"
      assert response["data"]["id"] == target.id
    end

    test "returns 'transaction:id_not_found' if the given ID was not found" do
      response = provider_request("/transaction.get", %{"id" => "tfr_12345678901234567890123456"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "transaction:id_not_found"

      assert response["data"]["description"] ==
               "There is no transaction corresponding to the provided id"
    end

    test "returns 'transaction:id_not_found' if the given ID format is invalid" do
      response = provider_request("/transaction.get", %{"id" => "not_valid_id"})

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
        provider_request("/transaction.create", %{
          "idempotency_token" => "123",
          "from_address" => wallet_1.address,
          "to_address" => wallet_2.address,
          "token_id" => token.id,
          "amount" => 1_000_000
        })

      assert response["success"]
      assert response["data"]["object"] == "transaction"
      assert response["data"]["status"] == "confirmed"
    end

    test "create a transaction with exchange" do
      account = Account.get_master_account()
      {:ok, user_1} = :user |> params_for() |> User.insert()
      {:ok, user_2} = :user |> params_for() |> User.insert()
      wallet_1 = User.get_primary_wallet(user_1)
      wallet_2 = User.get_primary_wallet(user_2)

      token_1 = insert(:token)
      token_2 = insert(:token)

      mint!(token_1)
      mint!(token_2)

      _pair = insert(:exchange_pair, from_token: token_1, to_token: token_2, rate: 2)

      set_initial_balance(%{
        address: wallet_1.address,
        token: token_1,
        amount: 2_000_000
      })

      response =
        provider_request("/transaction.create", %{
          "idempotency_token" => "12344",
          "from_address" => wallet_1.address,
          "to_address" => wallet_2.address,
          "from_token_id" => token_1.id,
          "to_token_id" => token_2.id,
          "exchange_account_id" => account.id,
          "from_amount" => 1_000
        })

      assert response["success"] == true
      assert response["data"]["object"] == "transaction"

      assert response["data"]["from"]["address"] == wallet_1.address
      assert response["data"]["from"]["amount"] == 1_000
      assert response["data"]["from"]["account_id"] == nil
      assert response["data"]["from"]["user_id"] == user_1.id
      assert response["data"]["from"]["token_id"] == token_1.id

      assert response["data"]["to"]["address"] == wallet_2.address
      assert response["data"]["to"]["amount"] == 2_000
      assert response["data"]["to"]["account_id"] == nil
      assert response["data"]["to"]["user_id"] == user_2.id
      assert response["data"]["to"]["token_id"] == token_2.id
    end

    test "returns :invalid_parameter when the sending address is a burn balance" do
      token = insert(:token)
      wallet_1 = insert(:wallet, identifier: "burn")
      wallet_2 = insert(:wallet, identifier: "primary")

      response =
        provider_request("/transaction.create", %{
          "idempotency_token" => "123",
          "from_address" => wallet_1.address,
          "to_address" => wallet_2.address,
          "token_id" => token.id,
          "amount" => 1_000_000
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "client:invalid_parameter",
               "description" =>
                 "Invalid parameter provided `from` can't be the address of a burn wallet.",
               "messages" => %{"from" => ["burn_wallet_as_sender_not_allowed"]},
               "object" => "error"
             }
    end

    test "returns transaction:insufficient_funds when the sending address does not have enough funds" do
      token = insert(:token)
      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)

      response =
        provider_request("/transaction.create", %{
          "idempotency_token" => "123",
          "from_address" => wallet_1.address,
          "to_address" => wallet_2.address,
          "token_id" => token.id,
          "amount" => 1_000_000
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "transaction:insufficient_funds",
               "description" =>
                 "The specified wallet (#{wallet_1.address}) does not contain enough funds. Available: 0 #{
                   token.id
                 } - Attempted debit: 10000 #{token.id}",
               "messages" => nil,
               "object" => "error"
             }
    end

    test "returns client:invalid_parameter when idempotency token is not given" do
      token = insert(:token)
      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)

      response =
        provider_request("/transaction.create", %{
          "from_address" => wallet_1.address,
          "to_address" => wallet_2.address,
          "token_id" => token.id,
          "amount" => 1_000_000
        })

      assert response["success"] == false

      assert response["data"] == %{
               "messages" => nil,
               "object" => "error",
               "code" => "client:invalid_parameter",
               "description" => "'idempotency_token' is required."
             }
    end

    test "returns wallet:to_address_not_found when from_address does not exist" do
      token = insert(:token)
      mint!(token)

      wallet_1 = insert(:wallet)

      set_initial_balance(%{
        address: wallet_1.address,
        token: token,
        amount: 2_000_000
      })

      response =
        provider_request("/transaction.create", %{
          "idempotency_token" => "123",
          "from_address" => wallet_1.address,
          "to_address" => "fake-0000-0000-0000",
          "token_id" => token.id,
          "amount" => 1_000_000
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "wallet:to_address_not_found",
               "description" => "No wallet found for the provided to_address.",
               "messages" => nil,
               "object" => "error"
             }
    end

    test "returns user:from_address_not_found when to_address does not exist" do
      token = insert(:token)
      wallet_2 = insert(:wallet)

      response =
        provider_request("/transaction.create", %{
          "idempotency_token" => "123",
          "from_address" => "fake-0000-0000-0000",
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
        provider_request("/transaction.create", %{
          "idempotency_token" => "123",
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

    test "returns :invalid_parameter when amount is invalid" do
      token = insert(:token)
      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)

      response =
        provider_request("/transaction.create", %{
          "idempotency_token" => "123",
          "from_address" => wallet_1.address,
          "to_address" => wallet_2.address,
          "token_id" => token.id,
          "amount" => "fake"
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "client:invalid_parameter",
               "description" => "String number is not a valid number: 'fake'.",
               "messages" => nil,
               "object" => "error"
             }
    end
  end
end
