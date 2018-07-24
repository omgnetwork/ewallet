defmodule AdminAPI.V1.AdminAuth.TransactionControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.TransactionGate
  alias EWalletDB.{User, Account, Repo, Transaction}

  # credo:disable-for-next-line
  setup do
    token = insert(:token)
    mint = token |> mint!(1_000_000) |> Repo.preload([:transaction])

    user = get_test_user()
    wallet_1 = User.get_primary_wallet(user)
    wallet_2 = insert(:wallet)
    wallet_3 = insert(:wallet)
    wallet_4 = insert(:wallet, user: user, identifier: "secondary")

    init_transaction_1 =
      set_initial_balance(%{address: wallet_1.address, token: token, amount: 10}, false)

    {:ok, transaction_1} =
      TransactionGate.create(%{
        "from_address" => wallet_1.address,
        "to_address" => wallet_2.address,
        "amount" => 1,
        "token_id" => token.id,
        "idempotency_token" => "1231"
      })

    assert transaction_1.status == "confirmed"

    init_transaction_2 =
      set_initial_balance(%{address: wallet_2.address, token: token, amount: 10}, false)

    {:ok, transaction_2} =
      TransactionGate.create(%{
        "from_address" => wallet_2.address,
        "to_address" => wallet_1.address,
        "amount" => 1,
        "token_id" => token.id,
        "idempotency_token" => "1232"
      })

    assert transaction_2.status == "confirmed"

    {:ok, transaction_3} =
      TransactionGate.create(%{
        "from_address" => wallet_1.address,
        "to_address" => wallet_3.address,
        "amount" => 1,
        "token_id" => token.id,
        "idempotency_token" => "1233"
      })

    assert transaction_3.status == "confirmed"

    transaction_4 =
      insert(:transaction, %{
        from_wallet: wallet_1,
        from_user_uuid: wallet_1.user_uuid,
        to_wallet: wallet_2,
        to_user_uuid: wallet_2.user_uuid,
        status: "pending"
      })

    transaction_5 = insert(:transaction, %{status: "confirmed"})
    transaction_6 = insert(:transaction, %{status: "pending"})

    init_transaction_3 =
      set_initial_balance(%{address: wallet_4.address, token: token, amount: 10}, false)

    {:ok, transaction_7} =
      TransactionGate.create(%{
        "from_address" => wallet_4.address,
        "to_address" => wallet_2.address,
        "amount" => 1,
        "token_id" => token.id,
        "idempotency_token" => "1237"
      })

    assert transaction_7.status == "confirmed"

    transaction_8 =
      insert(:transaction, %{
        from_wallet: wallet_4,
        from_user_uuid: wallet_4.user_uuid,
        to_wallet: wallet_3,
        to_user_uuid: wallet_3.user_uuid,
        status: "pending"
      })

    %{
      mint: mint,
      token: token,
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
      transaction_8: transaction_8,
      init_transaction_1: init_transaction_1,
      init_transaction_2: init_transaction_2,
      init_transaction_3: init_transaction_3
    }
  end

  describe "/transaction.all" do
    test "returns all the transactions", meta do
      response =
        admin_user_request("/transaction.all", %{
          "sort_by" => "created",
          "sort_dir" => "asc",
          "per_page" => 20
        })

      transactions = [
        meta.mint.transaction,
        meta.init_transaction_1,
        meta.transaction_1,
        meta.init_transaction_2,
        meta.transaction_2,
        meta.transaction_3,
        meta.transaction_4,
        meta.transaction_5,
        meta.transaction_6,
        meta.init_transaction_3,
        meta.transaction_7,
        meta.transaction_8
      ]

      saved_transactions = Repo.all(Transaction)
      assert length(response["data"]["data"]) == length(saved_transactions)
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
        admin_user_request("/transaction.all", %{
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "search_terms" => %{
            "from" => meta.wallet_1.address,
            "to" => meta.wallet_2.address
          }
        })

      assert response["data"]["data"] |> length() == 2

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transaction_1.id,
               meta.transaction_4.id
             ]
    end

    test "returns all transactions filtered", meta do
      response =
        admin_user_request("/transaction.all", %{
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
        admin_user_request("/transaction.all", %{
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "per_page" => 2,
          "page" => 1
        })

      assert response["data"]["data"] |> length() == 2
      transaction_1 = Enum.at(response["data"]["data"], 0)
      transaction_2 = Enum.at(response["data"]["data"], 1)
      assert transaction_2["created_at"] > transaction_1["created_at"]

      assert transaction_1["id"] == meta.mint.transaction.id
      assert transaction_2["id"] == meta.init_transaction_1.id
    end
  end

  describe "/account.get_transactions" do
    test "returns all the transactions", meta do
      account = Account.get_master_account()
      {:ok, account_1} = :account |> params_for() |> Account.insert()
      {:ok, account_2} = :account |> params_for() |> Account.insert()
      {:ok, account_3} = :account |> params_for() |> Account.insert()

      wallet_1 = Account.get_primary_wallet(account_1)
      wallet_2 = Account.get_primary_wallet(account_2)
      wallet_3 = Account.get_primary_wallet(account_3)

      set_initial_balance(%{address: wallet_1.address, token: meta.token, amount: 10}, false)
      set_initial_balance(%{address: wallet_2.address, token: meta.token, amount: 20}, false)
      set_initial_balance(%{address: wallet_3.address, token: meta.token, amount: 20}, false)

      response =
        admin_user_request("/account.get_transactions", %{
          "id" => account.id,
          "sort_by" => "created",
          "sort_dir" => "asc",
          "per_page" => 50
        })

      assert length(response["data"]["data"]) == 13
    end

    test "returns all the transactions when owned is true", meta do
      account = Account.get_master_account()
      {:ok, account_1} = :account |> params_for() |> Account.insert()
      {:ok, account_2} = :account |> params_for() |> Account.insert()
      {:ok, account_3} = :account |> params_for() |> Account.insert()

      wallet_1 = Account.get_primary_wallet(account_1)
      wallet_2 = Account.get_primary_wallet(account_2)
      wallet_3 = Account.get_primary_wallet(account_3)

      set_initial_balance(%{address: wallet_1.address, token: meta.token, amount: 10}, false)
      set_initial_balance(%{address: wallet_2.address, token: meta.token, amount: 20}, false)
      set_initial_balance(%{address: wallet_3.address, token: meta.token, amount: 20}, false)

      response =
        admin_user_request("/account.get_transactions", %{
          "id" => account.id,
          "owned" => true,
          "sort_by" => "created",
          "sort_dir" => "asc",
          "per_page" => 50
        })

      assert length(response["data"]["data"]) == 13
    end

    test "returns all the transactions for a specific address", meta do
      account = Account.get_master_account()

      response =
        admin_user_request("/account.get_transactions", %{
          "id" => account.id,
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "search_terms" => %{
            "from" => meta.wallet_1.address,
            "to" => meta.wallet_2.address
          }
        })

      assert response["data"]["data"] |> length() == 2

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transaction_1.id,
               meta.transaction_4.id
             ]
    end

    test "returns all transactions filtered", meta do
      account = Account.get_master_account()

      response =
        admin_user_request("/account.get_transactions", %{
          "id" => account.id,
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "search_term" => "pending"
        })

      assert response["data"]["data"] |> length() == 2

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transaction_4.id,
               meta.transaction_8.id
             ]
    end

    test "returns all transactions sorted and paginated", meta do
      account = Account.get_master_account()

      response =
        admin_user_request("/account.get_transactions", %{
          "id" => account.id,
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "per_page" => 2,
          "page" => 1
        })

      assert response["data"]["data"] |> length() == 2
      transaction_1 = Enum.at(response["data"]["data"], 0)
      transaction_2 = Enum.at(response["data"]["data"], 1)
      assert transaction_2["created_at"] > transaction_1["created_at"]

      assert transaction_1["id"] == meta.mint.transaction.id
      assert transaction_2["id"] == meta.init_transaction_1.id
    end
  end

  describe "/user.get_transactions" do
    test "returns all the transactions for a specific user_id", meta do
      response =
        admin_user_request("/user.get_transactions", %{
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "user_id" => meta.user.id
        })

      assert response["data"]["data"] |> length() == 8

      Enum.each(response["data"]["data"], fn tx ->
        assert Enum.member?([tx["from"]["user_id"], tx["to"]["user_id"]], meta.user.id)
      end)
    end

    test "returns all the transactions for a specific provider_user_id", meta do
      response =
        admin_user_request("/user.get_transactions", %{
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "provider_user_id" => meta.user.provider_user_id
        })

      assert response["data"]["data"] |> length() == 8

      Enum.each(response["data"]["data"], fn tx ->
        assert Enum.member?([tx["from"]["user_id"], tx["to"]["user_id"]], meta.user.id)
      end)
    end

    test "returns the user's transactions even when different search terms are provided", meta do
      response =
        admin_user_request("/user.get_transactions", %{
          "provider_user_id" => meta.user.provider_user_id,
          "sort_by" => "created_at",
          "sort_dir" => "desc",
          "search_terms" => %{}
        })

      assert response["data"]["data"] |> length() == 8

      Enum.each(response["data"]["data"], fn tx ->
        assert Enum.member?([tx["from"]["user_id"], tx["to"]["user_id"]], meta.user.id)
      end)
    end

    test "returns all transactions filtered", meta do
      response =
        admin_user_request("/user.get_transactions", %{
          "provider_user_id" => meta.user.provider_user_id,
          "search_terms" => %{"status" => "pending"}
        })

      assert response["data"]["data"] |> length() == 2

      Enum.each(response["data"]["data"], fn tx ->
        assert Enum.member?([tx["from"]["user_id"], tx["to"]["user_id"]], meta.user.id)
      end)
    end

    test "returns all transactions sorted and paginated", meta do
      response =
        admin_user_request("/user.get_transactions", %{
          "provider_user_id" => meta.user.provider_user_id,
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "per_page" => 3,
          "page" => 1
        })

      assert response["data"]["data"] |> length() == 3

      assert NaiveDateTime.compare(
               meta.transaction_1.inserted_at,
               meta.transaction_2.inserted_at
             ) == :lt

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.init_transaction_1.id,
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
      response = admin_user_request("/transaction.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "transaction"
      assert response["data"]["id"] == target.id
    end

    test "returns 'transaction:id_not_found' if the given ID was not found" do
      response =
        admin_user_request("/transaction.get", %{"id" => "tfr_12345678901234567890123456"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "transaction:id_not_found"

      assert response["data"]["description"] ==
               "There is no transaction corresponding to the provided id"
    end

    test "returns 'transaction:id_not_found' if the given ID format is invalid" do
      response = admin_user_request("/transaction.get", %{"id" => "not_valid_id"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "transaction:id_not_found"

      assert response["data"]["description"] ==
               "There is no transaction corresponding to the provided id"
    end
  end

  describe "/transaction.create for same-token transactions" do
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
        admin_user_request("/transaction.create", %{
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

    test "creates a transaction when all params are valid with big numbers" do
      token = insert(:token)
      mint!(token)

      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)

      set_initial_balance(%{
        address: wallet_1.address,
        token: token,
        amount: 999_999_999_999_999_999_999_999_999
      })

      response =
        admin_user_request("/transaction.create", %{
          "idempotency_token" => "123",
          "from_address" => wallet_1.address,
          "to_address" => wallet_2.address,
          "token_id" => token.id,
          "amount" => 99_999_999_999_999_999_999_999_999
        })

      assert response["success"]
      assert response["data"]["object"] == "transaction"
      assert response["data"]["status"] == "confirmed"

      assert response["data"]["from"]["amount"] == 99_999_999_999_999_999_999_999_999
    end

    test "returns a transaction when passing `from_amount` and `to_amount` instead of `amount`" do
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
        admin_user_request("/transaction.create", %{
          "idempotency_token" => "123",
          "from_address" => wallet_1.address,
          "to_address" => wallet_2.address,
          "token_id" => token.id,
          "from_amount" => 1_000_000,
          "to_amount" => 1_000_000
        })

      assert response["success"]
      assert response["data"]["object"] == "transaction"
      assert response["data"]["status"] == "confirmed"
    end

    test "returns :invalid_parameter when the sending address is a burn balance" do
      token = insert(:token)
      wallet_1 = insert(:wallet, identifier: "burn")
      wallet_2 = insert(:wallet, identifier: "primary")

      response =
        admin_user_request("/transaction.create", %{
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
      token = insert(:token, subunit_to_unit: 100)
      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)

      response =
        admin_user_request("/transaction.create", %{
          "idempotency_token" => "123",
          "from_address" => wallet_1.address,
          "to_address" => wallet_2.address,
          "token_id" => token.id,
          "amount" => 1_234_567
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "transaction:insufficient_funds",
               "description" =>
                 "The specified wallet (#{wallet_1.address}) does not contain enough funds. Available: 0 #{
                   token.id
                 } - Attempted debit: 12345.67 #{token.id}",
               "messages" => nil,
               "object" => "error"
             }

      transaction = get_last_inserted(Transaction)
      assert transaction.error_code == "insufficient_funds"
      assert transaction.error_description == nil

      assert transaction.error_data == %{
               "address" => wallet_1.address,
               "amount_to_debit" => 1_234_567,
               "current_amount" => 0,
               "token_id" => token.id
             }
    end

    test "returns client:invalid_parameter when idempotency token is not given" do
      token = insert(:token)
      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)

      response =
        admin_user_request("/transaction.create", %{
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
        admin_user_request("/transaction.create", %{
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

    test "returns token:id_not_found when token_id does not exist" do
      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)

      response =
        admin_user_request("/transaction.create", %{
          "idempotency_token" => "123",
          "from_address" => wallet_1.address,
          "to_address" => wallet_2.address,
          "token_id" => "fake",
          "amount" => 1_000_000
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "token:id_not_found",
               "description" => "There is no token corresponding to the provided id",
               "messages" => nil,
               "object" => "error"
             }
    end

    test "returns :invalid_parameter when amount is invalid" do
      token = insert(:token)
      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)

      response =
        admin_user_request("/transaction.create", %{
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

    test "returns unauthorized error when from_address does not exist" do
      token = insert(:token)
      wallet_2 = insert(:wallet)

      response =
        admin_user_request("/transaction.create", %{
          "idempotency_token" => "123",
          "from_address" => "fake-0000-0000-0000",
          "to_address" => wallet_2.address,
          "token_id" => token.id,
          "amount" => 1_000_000
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "unauthorized",
               "description" => "You are not allowed to perform the requested operation",
               "messages" => nil,
               "object" => "error"
             }
    end
  end

  describe "/transaction.create for cross-token transactions" do
    test "returns the created transaction" do
      account = Account.get_master_account()
      {:ok, user_1} = :user |> params_for() |> User.insert()
      {:ok, user_2} = :user |> params_for() |> User.insert()
      wallet_1 = User.get_primary_wallet(user_1)
      wallet_2 = User.get_primary_wallet(user_2)

      token_1 = insert(:token)
      token_2 = insert(:token)

      mint!(token_1)
      mint!(token_2)

      pair = insert(:exchange_pair, from_token: token_1, to_token: token_2, rate: 2)

      set_initial_balance(%{
        address: wallet_1.address,
        token: token_1,
        amount: 2_000_000
      })

      response =
        admin_user_request("/transaction.create", %{
          "idempotency_token" => "12344",
          "exchange_account_id" => account.id,
          "from_amount" => 1_000,
          "from_token_id" => token_1.id,
          "from_address" => wallet_1.address,
          "to_amount" => 1_000 * pair.rate,
          "to_token_id" => token_2.id,
          "to_address" => wallet_2.address
        })

      assert response["success"] == true
      assert response["data"]["object"] == "transaction"

      assert response["data"]["exchange"]["rate"] == 2
      assert response["data"]["exchange"]["calculated_at"] != nil
      assert response["data"]["exchange"]["exchange_pair_id"] == pair.id
      assert response["data"]["exchange"]["exchange_pair"]["id"] == pair.id

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

    test "returns the created transaction with an unfixed from_amount" do
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
        admin_user_request("/transaction.create", %{
          "idempotency_token" => "12344",
          "exchange_account_id" => account.id,
          # "from_amount" => 1_000 / pair.rate,
          "from_token_id" => token_1.id,
          "from_address" => wallet_1.address,
          "to_amount" => 2_000,
          "to_token_id" => token_2.id,
          "to_address" => wallet_2.address
        })

      assert response["success"] == true
      assert response["data"]["object"] == "transaction"

      assert response["data"]["from"]["amount"] == 1_000
      assert response["data"]["from"]["token_id"] == token_1.id

      assert response["data"]["to"]["amount"] == 2_000
      assert response["data"]["to"]["token_id"] == token_2.id
    end

    test "returns the created transaction with an unfixed to_amount" do
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
        admin_user_request("/transaction.create", %{
          "idempotency_token" => "12344",
          "exchange_account_id" => account.id,
          "from_amount" => 1_000,
          "from_token_id" => token_1.id,
          "from_address" => wallet_1.address,
          # "to_amount" => 1_000 * pair.rate,
          "to_token_id" => token_2.id,
          "to_address" => wallet_2.address
        })

      assert response["success"] == true
      assert response["data"]["object"] == "transaction"

      assert response["data"]["from"]["amount"] == 1_000
      assert response["data"]["from"]["token_id"] == token_1.id

      assert response["data"]["to"]["amount"] == 2_000
      assert response["data"]["to"]["token_id"] == token_2.id
    end

    test "returns the created transaction when `from_amount` and `to_amount` are equal" do
      account = Account.get_master_account()
      {:ok, user_1} = :user |> params_for() |> User.insert()
      {:ok, user_2} = :user |> params_for() |> User.insert()
      wallet_1 = User.get_primary_wallet(user_1)
      wallet_2 = User.get_primary_wallet(user_2)

      token_1 = insert(:token)
      token_2 = insert(:token)

      mint!(token_1)
      mint!(token_2)

      _pair = insert(:exchange_pair, from_token: token_1, to_token: token_2, rate: 1)

      set_initial_balance(%{
        address: wallet_1.address,
        token: token_1,
        amount: 2_000_000
      })

      response =
        admin_user_request("/transaction.create", %{
          "idempotency_token" => "12344",
          "exchange_account_id" => account.id,
          "from_amount" => 1_000,
          "from_token_id" => token_1.id,
          "from_address" => wallet_1.address,
          "to_amount" => 1_000,
          "to_token_id" => token_2.id,
          "to_address" => wallet_2.address
        })

      assert response["success"] == true
      assert response["data"]["object"] == "transaction"

      assert response["data"]["from"]["amount"] == 1_000
      assert response["data"]["from"]["token_id"] == token_1.id

      assert response["data"]["to"]["amount"] == 1_000
      assert response["data"]["to"]["token_id"] == token_2.id
    end

    test "create a transaction with exchange_account_id" do
      account = Account.get_master_account()
      {:ok, user_1} = :user |> params_for() |> User.insert()
      {:ok, user_2} = :user |> params_for() |> User.insert()
      wallet_1 = User.get_primary_wallet(user_1)
      wallet_2 = User.get_primary_wallet(user_2)

      token_1 = insert(:token)
      token_2 = insert(:token)

      mint!(token_1)
      mint!(token_2)

      pair = insert(:exchange_pair, from_token: token_1, to_token: token_2, rate: 2)

      set_initial_balance(%{
        address: wallet_1.address,
        token: token_1,
        amount: 2_000_000
      })

      response =
        admin_user_request("/transaction.create", %{
          "idempotency_token" => "12344",
          "exchange_account_id" => account.id,
          "from_amount" => 1_000,
          "from_token_id" => token_1.id,
          "from_address" => wallet_1.address,
          "to_amount" => 1_000 * pair.rate,
          "to_token_id" => token_2.id,
          "to_address" => wallet_2.address
        })

      assert response["success"] == true
      assert response["data"]["object"] == "transaction"
      assert response["data"]["exchange"]["exchange_wallet"]["account_id"] == account.id

      assert response["data"]["exchange"]["exchange_wallet_address"] ==
               Account.get_primary_wallet(account).address
    end

    test "create a transaction with exchange_wallet_address" do
      account = Account.get_master_account()
      exchange_address = Account.get_primary_wallet(account).address
      {:ok, user_1} = :user |> params_for() |> User.insert()
      {:ok, user_2} = :user |> params_for() |> User.insert()
      wallet_1 = User.get_primary_wallet(user_1)
      wallet_2 = User.get_primary_wallet(user_2)

      token_1 = insert(:token)
      token_2 = insert(:token)

      mint!(token_1)
      mint!(token_2)

      pair = insert(:exchange_pair, from_token: token_1, to_token: token_2, rate: 2)

      set_initial_balance(%{
        address: wallet_1.address,
        token: token_1,
        amount: 2_000_000
      })

      response =
        admin_user_request("/transaction.create", %{
          "idempotency_token" => "12344",
          "exchange_wallet_address" => exchange_address,
          "from_amount" => 1_000,
          "from_token_id" => token_1.id,
          "from_address" => wallet_1.address,
          "to_amount" => 1_000 * pair.rate,
          "to_token_id" => token_2.id,
          "to_address" => wallet_2.address
        })

      assert response["success"] == true
      assert response["data"]["object"] == "transaction"
      assert response["data"]["exchange"]["exchange_wallet_address"] == exchange_address
    end

    test "create a transaction with exchange wallet also being the `from` wallet" do
      exchange_account = Account.get_master_account()
      exchange_wallet = Account.get_primary_wallet(exchange_account)
      {:ok, user} = :user |> params_for() |> User.insert()
      user_wallet = User.get_primary_wallet(user)

      token_1 = insert(:token)
      token_2 = insert(:token)

      mint!(token_1)
      mint!(token_2)

      pair = insert(:exchange_pair, from_token: token_1, to_token: token_2, rate: 2)

      response =
        admin_user_request("/transaction.create", %{
          "idempotency_token" => "12344",
          "exchange_account_id" => exchange_account.id,
          "from_amount" => 1_000,
          "from_token_id" => token_1.id,
          "from_address" => exchange_wallet.address,
          "to_amount" => 1_000 * pair.rate,
          "to_token_id" => token_2.id,
          "to_address" => user_wallet.address
        })

      assert response["success"] == true
      assert response["data"]["object"] == "transaction"
      assert response["data"]["from"]["address"] == exchange_wallet.address
      assert response["data"]["to"]["address"] == user_wallet.address
    end

    test "creates a transaction with exchange wallet also being the `to` wallet" do
      exchange_account = Account.get_master_account()
      exchange_wallet = Account.get_primary_wallet(exchange_account)
      {:ok, user} = :user |> params_for() |> User.insert()
      user_wallet = User.get_primary_wallet(user)

      token_1 = insert(:token)
      token_2 = insert(:token)

      mint!(token_1)
      mint!(token_2)

      pair = insert(:exchange_pair, from_token: token_1, to_token: token_2, rate: 2)

      set_initial_balance(%{
        address: user_wallet.address,
        token: token_1,
        amount: 2_000_000
      })

      response =
        admin_user_request("/transaction.create", %{
          "idempotency_token" => "12344",
          "exchange_account_id" => exchange_account.id,
          "from_amount" => 1_000,
          "from_token_id" => token_1.id,
          "from_address" => user_wallet.address,
          "to_amount" => 1_000 * pair.rate,
          "to_token_id" => token_2.id,
          "to_address" => exchange_wallet.address
        })

      assert response["success"] == true
      assert response["data"]["object"] == "transaction"
      assert response["data"]["from"]["address"] == user_wallet.address
      assert response["data"]["to"]["address"] == exchange_wallet.address
    end

    test "returns an error when doing a cross-token transaction with invalid rate" do
      {:ok, user_1} = :user |> params_for() |> User.insert()
      {:ok, user_2} = :user |> params_for() |> User.insert()

      wallet_1 = User.get_primary_wallet(user_1)
      wallet_2 = User.get_primary_wallet(user_2)

      token_1 = insert(:token)
      token_2 = insert(:token)

      _pair = insert(:exchange_pair, from_token: token_1, to_token: token_2, rate: 2)

      response =
        admin_user_request("/transaction.create", %{
          "idempotency_token" => "12344",
          "exchange_account_id" => "fake",
          "from_amount" => 1_000,
          "from_token_id" => token_1.id,
          "from_address" => wallet_1.address,
          "to_amount" => 10_000,
          "to_token_id" => token_2.id,
          "to_address" => wallet_2.address
        })

      assert response["success"] == false
      assert response["data"]["code"] == "exchange:invalid_rate"
    end

    test "returns an error when doing a cross-token transaction with invalid rate and same amounts" do
      {:ok, user_1} = :user |> params_for() |> User.insert()
      {:ok, user_2} = :user |> params_for() |> User.insert()

      wallet_1 = User.get_primary_wallet(user_1)
      wallet_2 = User.get_primary_wallet(user_2)

      token_1 = insert(:token)
      token_2 = insert(:token)

      _pair = insert(:exchange_pair, from_token: token_1, to_token: token_2, rate: 2)

      response =
        admin_user_request("/transaction.create", %{
          "idempotency_token" => "12344",
          "exchange_account_id" => "fake",
          "from_amount" => 1_000,
          "from_token_id" => token_1.id,
          "from_address" => wallet_1.address,
          "to_amount" => 1_000,
          "to_token_id" => token_2.id,
          "to_address" => wallet_2.address
        })

      assert response["success"] == false
      assert response["data"]["code"] == "exchange:invalid_rate"
    end

    test "returns an error when doing a cross-token transaction with invalid exchange_account_id" do
      {:ok, user_1} = :user |> params_for() |> User.insert()
      {:ok, user_2} = :user |> params_for() |> User.insert()

      wallet_1 = User.get_primary_wallet(user_1)
      wallet_2 = User.get_primary_wallet(user_2)

      token_1 = insert(:token)
      token_2 = insert(:token)

      pair = insert(:exchange_pair, from_token: token_1, to_token: token_2, rate: 2)

      response =
        admin_user_request("/transaction.create", %{
          "idempotency_token" => "12344",
          "exchange_account_id" => "fake",
          "from_amount" => 1_000,
          "from_token_id" => token_1.id,
          "from_address" => wallet_1.address,
          "to_amount" => 1_000 * pair.rate,
          "to_token_id" => token_2.id,
          "to_address" => wallet_2.address
        })

      assert response["success"] == false
      assert response["data"]["code"] == "exchange:account_id_not_found"
    end

    test "returns user:same_address when `from` and `to` and exchange wallet are the same address" do
      exchange_account = Account.get_master_account()
      wallet = Account.get_primary_wallet(exchange_account)

      token_1 = insert(:token)
      token_2 = insert(:token)

      mint!(token_1)
      mint!(token_2)

      pair = insert(:exchange_pair, from_token: token_1, to_token: token_2, rate: 2)

      response =
        admin_user_request("/transaction.create", %{
          "idempotency_token" => "123",
          "exchange_account_id" => exchange_account.id,
          "from_amount" => 1_000,
          "from_token_id" => token_1.id,
          "from_address" => wallet.address,
          "to_amount" => 1_000 * pair.rate,
          "to_token_id" => token_2.id,
          "to_address" => wallet.address
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "transaction:same_address",
               "description" =>
                 "Found identical addresses in senders and receivers: #{wallet.address}.",
               "messages" => nil,
               "object" => "error"
             }
    end
  end
end
