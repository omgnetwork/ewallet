# Copyright 2018 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule AdminAPI.V1.TransactionControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.TransactionGate
  alias EWalletDB.{Account, Repo, Token, Transaction, User}
  alias ActivityLogger.System
  alias Utils.Helpers.DateFormatter

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
        "idempotency_token" => "1231",
        "originator" => %System{}
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
        "idempotency_token" => "1232",
        "originator" => %System{}
      })

    assert transaction_2.status == "confirmed"

    {:ok, transaction_3} =
      TransactionGate.create(%{
        "from_address" => wallet_1.address,
        "to_address" => wallet_3.address,
        "amount" => 1,
        "token_id" => token.id,
        "idempotency_token" => "1233",
        "originator" => %System{}
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
        "idempotency_token" => "1237",
        "originator" => %System{}
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
    test_with_auths "returns all the transactions", context do
      response =
        request("/transaction.all", %{
          "sort_by" => "created",
          "sort_dir" => "asc",
          "per_page" => 20
        })

      transactions = [
        context.mint.transaction,
        context.init_transaction_1,
        context.transaction_1,
        context.init_transaction_2,
        context.transaction_2,
        context.transaction_3,
        context.transaction_4,
        context.transaction_5,
        context.transaction_6,
        context.init_transaction_3,
        context.transaction_7,
        context.transaction_8
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

    test_with_auths "returns all the transactions for a specific address", context do
      response =
        request("/transaction.all", %{
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "search_terms" => %{
            "from" => context.wallet_1.address,
            "to" => context.wallet_2.address
          }
        })

      assert response["data"]["data"] |> length() == 2

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               context.transaction_1.id,
               context.transaction_4.id
             ]
    end

    test_with_auths "returns all transactions filtered", context do
      response =
        request("/transaction.all", %{
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "search_term" => "pending"
        })

      assert response["data"]["data"] |> length() == 3

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               context.transaction_4.id,
               context.transaction_6.id,
               context.transaction_8.id
             ]
    end

    test_with_auths "returns all transactions sorted and paginated", context do
      response =
        request("/transaction.all", %{
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "per_page" => 2,
          "page" => 1
        })

      assert response["data"]["data"] |> length() == 2
      transaction_1 = Enum.at(response["data"]["data"], 0)
      transaction_2 = Enum.at(response["data"]["data"], 1)
      assert transaction_2["created_at"] > transaction_1["created_at"]

      assert transaction_1["id"] == context.mint.transaction.id
      assert transaction_2["id"] == context.init_transaction_1.id
    end

    test_with_auths "returns match_all filtered transactions", context do
      response =
        request("/transaction.all", %{
          "match_all" => [
            %{
              "field" => "from_wallet.address",
              "comparator" => "eq",
              "value" => context.wallet_4.address
            },
            %{
              "field" => "status",
              "comparator" => "eq",
              "value" => "confirmed"
            }
          ]
        })

      transactions = response["data"]["data"]

      refute Enum.any?(transactions, fn txn -> txn["id"] == context.transaction_1.id end)
      refute Enum.any?(transactions, fn txn -> txn["id"] == context.transaction_2.id end)
      refute Enum.any?(transactions, fn txn -> txn["id"] == context.transaction_3.id end)
      refute Enum.any?(transactions, fn txn -> txn["id"] == context.transaction_4.id end)
      refute Enum.any?(transactions, fn txn -> txn["id"] == context.transaction_5.id end)
      refute Enum.any?(transactions, fn txn -> txn["id"] == context.transaction_6.id end)
      assert Enum.any?(transactions, fn txn -> txn["id"] == context.transaction_7.id end)
      refute Enum.any?(transactions, fn txn -> txn["id"] == context.transaction_8.id end)
    end

    test_with_auths "returns match_any filtered transactions", context do
      response =
        request("/transaction.all", %{
          "match_any" => [
            %{
              "field" => "from_wallet.address",
              "comparator" => "eq",
              "value" => context.wallet_2.address
            },
            %{
              "field" => "from_wallet.address",
              "comparator" => "eq",
              "value" => context.wallet_4.address
            }
          ]
        })

      transactions = response["data"]["data"]

      refute Enum.any?(transactions, fn txn -> txn["id"] == context.transaction_1.id end)
      assert Enum.any?(transactions, fn txn -> txn["id"] == context.transaction_2.id end)
      refute Enum.any?(transactions, fn txn -> txn["id"] == context.transaction_3.id end)
      refute Enum.any?(transactions, fn txn -> txn["id"] == context.transaction_4.id end)
      refute Enum.any?(transactions, fn txn -> txn["id"] == context.transaction_5.id end)
      refute Enum.any?(transactions, fn txn -> txn["id"] == context.transaction_6.id end)
      assert Enum.any?(transactions, fn txn -> txn["id"] == context.transaction_7.id end)
      assert Enum.any?(transactions, fn txn -> txn["id"] == context.transaction_8.id end)
    end

    test_supports_match_any("/transaction.all", :transaction, :idempotency_token)
    test_supports_match_all("/transaction.all", :transaction, :idempotency_token)
  end

  describe "/account.get_transactions" do
    test_with_auths "returns all the transactions", context do
      account = Account.get_master_account()
      {:ok, account_1} = :account |> params_for() |> Account.insert()
      {:ok, account_2} = :account |> params_for() |> Account.insert()
      {:ok, account_3} = :account |> params_for() |> Account.insert()

      wallet_1 = Account.get_primary_wallet(account_1)
      wallet_2 = Account.get_primary_wallet(account_2)
      wallet_3 = Account.get_primary_wallet(account_3)

      set_initial_balance(%{address: wallet_1.address, token: context.token, amount: 10}, false)
      set_initial_balance(%{address: wallet_2.address, token: context.token, amount: 20}, false)
      set_initial_balance(%{address: wallet_3.address, token: context.token, amount: 20}, false)

      response =
        request("/account.get_transactions", %{
          "id" => account.id,
          "sort_by" => "created",
          "sort_dir" => "asc",
          "per_page" => 50
        })

      assert length(response["data"]["data"]) == 15
    end

    test_with_auths "returns all the transactions when owned is true", context do
      account = Account.get_master_account()
      {:ok, account_1} = :account |> params_for() |> Account.insert()
      {:ok, account_2} = :account |> params_for() |> Account.insert()
      {:ok, account_3} = :account |> params_for() |> Account.insert()

      wallet_1 = Account.get_primary_wallet(account_1)
      wallet_2 = Account.get_primary_wallet(account_2)
      wallet_3 = Account.get_primary_wallet(account_3)

      set_initial_balance(%{address: wallet_1.address, token: context.token, amount: 10}, false)
      set_initial_balance(%{address: wallet_2.address, token: context.token, amount: 20}, false)
      set_initial_balance(%{address: wallet_3.address, token: context.token, amount: 20}, false)

      response =
        request("/account.get_transactions", %{
          "id" => account.id,
          "owned" => true,
          "sort_by" => "created",
          "sort_dir" => "asc",
          "per_page" => 50
        })

      assert length(response["data"]["data"]) == 15
    end

    test_with_auths "returns all the transactions for a specific address", context do
      account = Account.get_master_account()

      response =
        request("/account.get_transactions", %{
          "id" => account.id,
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "search_terms" => %{
            "from" => context.wallet_1.address,
            "to" => context.wallet_2.address
          }
        })

      assert response["data"]["data"] |> length() == 2

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               context.transaction_1.id,
               context.transaction_4.id
             ]
    end

    test_with_auths "returns all transactions filtered", context do
      account = Account.get_master_account()

      response =
        request("/account.get_transactions", %{
          "id" => account.id,
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "search_term" => "pending"
        })

      assert response["data"]["data"] |> length() == 3

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               context.transaction_4.id,
               context.transaction_6.id,
               context.transaction_8.id
             ]
    end

    test_with_auths "returns all transactions sorted and paginated", context do
      account = Account.get_master_account()

      response =
        request("/account.get_transactions", %{
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

      assert transaction_1["id"] == context.mint.transaction.id
      assert transaction_2["id"] == context.init_transaction_1.id
    end
  end

  describe "/user.get_transactions" do
    test_with_auths "returns all the transactions for a specific user_id", context do
      response =
        request("/user.get_transactions", %{
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "user_id" => context.user.id
        })

      assert response["data"]["data"] |> length() == 8

      Enum.each(response["data"]["data"], fn tx ->
        assert Enum.member?([tx["from"]["user_id"], tx["to"]["user_id"]], context.user.id)
      end)
    end

    test_with_auths "returns all the transactions for a specific provider_user_id", context do
      response =
        request("/user.get_transactions", %{
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "provider_user_id" => context.user.provider_user_id
        })

      assert response["data"]["data"] |> length() == 8

      Enum.each(response["data"]["data"], fn tx ->
        assert Enum.member?([tx["from"]["user_id"], tx["to"]["user_id"]], context.user.id)
      end)
    end

    test_with_auths "returns the user's transactions even when different search terms are provided",
                    context do
      response =
        request("/user.get_transactions", %{
          "provider_user_id" => context.user.provider_user_id,
          "sort_by" => "created_at",
          "sort_dir" => "desc",
          "search_terms" => %{}
        })

      assert response["data"]["data"] |> length() == 8

      Enum.each(response["data"]["data"], fn tx ->
        assert Enum.member?([tx["from"]["user_id"], tx["to"]["user_id"]], context.user.id)
      end)
    end

    test_with_auths "returns all transactions filtered", context do
      response =
        request("/user.get_transactions", %{
          "provider_user_id" => context.user.provider_user_id,
          "search_terms" => %{"status" => "pending"}
        })

      assert response["data"]["data"] |> length() == 2

      Enum.each(response["data"]["data"], fn tx ->
        assert Enum.member?([tx["from"]["user_id"], tx["to"]["user_id"]], context.user.id)
      end)
    end

    test_with_auths "returns all transactions sorted and paginated", context do
      response =
        request("/user.get_transactions", %{
          "provider_user_id" => context.user.provider_user_id,
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "per_page" => 3,
          "page" => 1
        })

      assert response["data"]["data"] |> length() == 3

      assert NaiveDateTime.compare(
               context.transaction_1.inserted_at,
               context.transaction_2.inserted_at
             ) == :lt

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               context.init_transaction_1.id,
               context.transaction_1.id,
               context.transaction_2.id
             ]
    end
  end

  describe "/transaction.get" do
    test_with_auths "returns a transaction by the given transaction's ID" do
      transactions = insert_list(3, :transaction)
      # Pick the 2nd inserted transaction
      target = Enum.at(transactions, 1)
      response = request("/transaction.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "transaction"
      assert response["data"]["id"] == target.id
    end

    test_with_auths "returns 'unauthorized' if the given ID was not found" do
      response = request("/transaction.get", %{"id" => "tfr_12345678901234567890123456"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end

    test_with_auths "returns 'transaction:id_not_found' if the given ID format is invalid" do
      response = request("/transaction.get", %{"id" => "not_valid_id"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end
  end

  describe "/transaction.create for same-token transactions" do
    test_with_auths "creates a transaction when all params are valid" do
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
        request("/transaction.create", %{
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

    test_with_auths "creates a transaction when all params are valid with big numbers" do
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
        request("/transaction.create", %{
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

    test_with_auths "returns a transaction when passing `from_amount` and `to_amount` instead of `amount`" do
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
        request("/transaction.create", %{
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

    test_with_auths "returns :invalid_parameter when the sending address is a burn balance" do
      token = insert(:token)
      wallet_1 = insert(:wallet, identifier: "burn")
      wallet_2 = insert(:wallet, identifier: "primary")

      response =
        request("/transaction.create", %{
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
                 "Invalid parameter provided. `from` can't be the address of a burn wallet.",
               "messages" => %{"from" => ["burn_wallet_as_sender_not_allowed"]},
               "object" => "error"
             }
    end

    test_with_auths "returns transaction:insufficient_funds when the sending address does not have enough funds" do
      token = insert(:token, subunit_to_unit: 100)
      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)

      response =
        request("/transaction.create", %{
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

    test_with_auths "returns client:invalid_parameter when idempotency token is not given" do
      token = insert(:token)
      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)

      response =
        request("/transaction.create", %{
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
               "description" => "Invalid parameter provided. `idempotency_token` is required."
             }
    end

    test_with_auths "returns wallet:to_address_not_found when from_address does not exist" do
      token = insert(:token)
      mint!(token)

      wallet_1 = insert(:wallet)

      set_initial_balance(%{
        address: wallet_1.address,
        token: token,
        amount: 2_000_000
      })

      response =
        request("/transaction.create", %{
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

    test_with_auths "returns token:id_not_found when token_id does not exist" do
      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)

      response =
        request("/transaction.create", %{
          "idempotency_token" => "123",
          "from_address" => wallet_1.address,
          "to_address" => wallet_2.address,
          "token_id" => "fake",
          "amount" => 1_000_000
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "token:id_not_found",
               "description" => "There is no token corresponding to the provided id.",
               "messages" => nil,
               "object" => "error"
             }
    end

    test_with_auths "returns :invalid_parameter when amount is invalid" do
      token = insert(:token)
      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)

      response =
        request("/transaction.create", %{
          "idempotency_token" => "123",
          "from_address" => wallet_1.address,
          "to_address" => wallet_2.address,
          "token_id" => token.id,
          "amount" => "fake"
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "client:invalid_parameter",
               "description" =>
                 "Invalid parameter provided. String number is not a valid number: 'fake'.",
               "messages" => nil,
               "object" => "error"
             }
    end

    test_with_auths "returns unauthorized error when from_address does not exist" do
      token = insert(:token)
      wallet_2 = insert(:wallet)

      response =
        request("/transaction.create", %{
          "idempotency_token" => "123",
          "from_address" => "fake-0000-0000-0000",
          "to_address" => wallet_2.address,
          "token_id" => token.id,
          "amount" => 1_000_000
        })

      assert response["success"] == false

      assert response["data"] == %{
               "code" => "unauthorized",
               "description" => "You are not allowed to perform the requested operation.",
               "messages" => nil,
               "object" => "error"
             }
    end

    test_with_auths "fails to create a transaction when token is disabled" do
      token = insert(:token)
      mint!(token)

      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)

      set_initial_balance(%{
        address: wallet_1.address,
        token: token,
        amount: 2_000_000
      })

      {:ok, token} =
        Token.enable_or_disable(token, %{
          enabled: false,
          originator: %System{}
        })

      response =
        request("/transaction.create", %{
          "idempotency_token" => "123",
          "from_address" => wallet_1.address,
          "to_address" => wallet_2.address,
          "token_id" => token.id,
          "amount" => 1_000_000
        })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "token:disabled"
    end

    defp assert_create_without_exchange_logs(logs, originator, target) do
      assert Enum.count(logs) == 2

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: originator,
        target: target,
        changes: %{
          "from" => target.from_wallet.address,
          "from_user_uuid" => target.from_user.uuid,
          "to" => target.to_wallet.address,
          "from_token_uuid" => target.from_token.uuid,
          "to_user_uuid" => target.to_user.uuid,
          "idempotency_token" => target.idempotency_token,
          "from_amount" => target.from_amount,
          "to_amount" => target.to_amount,
          "to_token_uuid" => target.to_token.uuid
        },
        encrypted_changes: %{
          "payload" => %{
            "from_address" => target.from_wallet.address,
            "to_address" => target.to_wallet.address,
            "idempotency_token" => target.idempotency_token,
            "amount" => target.to_amount,
            "token_id" => target.to_token.id
          }
        }
      )

      logs
      |> Enum.at(1)
      |> assert_activity_log(
        action: "update",
        originator: :system,
        target: target,
        changes: %{
          "local_ledger_uuid" => target.local_ledger_uuid,
          "status" => "confirmed"
        },
        encrypted_changes: %{}
      )
    end

    test "generates an activity log for an admin request" do
      token = insert(:token)
      mint!(token)

      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)

      set_initial_balance(%{
        address: wallet_1.address,
        token: token,
        amount: 2_000_000
      })

      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/transaction.create", %{
          "idempotency_token" => "123",
          "from_address" => wallet_1.address,
          "to_address" => wallet_2.address,
          "token_id" => token.id,
          "amount" => 1_000_000
        })

      assert response["success"] == true

      transaction =
        response["data"]["id"]
        |> Transaction.get()
        |> Repo.preload([
          :from_wallet,
          :from_token,
          :from_wallet,
          :from_user,
          :to_wallet,
          :to_token,
          :to_user
        ])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_create_without_exchange_logs(get_test_admin(), transaction)
    end

    test "generates an activity log for a provider request" do
      token = insert(:token)
      mint!(token)

      wallet_1 = insert(:wallet)
      wallet_2 = insert(:wallet)

      set_initial_balance(%{
        address: wallet_1.address,
        token: token,
        amount: 2_000_000
      })

      timestamp = DateTime.utc_now()

      response =
        provider_request("/transaction.create", %{
          "idempotency_token" => "123",
          "from_address" => wallet_1.address,
          "to_address" => wallet_2.address,
          "token_id" => token.id,
          "amount" => 1_000_000
        })

      assert response["success"] == true

      transaction =
        response["data"]["id"]
        |> Transaction.get()
        |> Repo.preload([
          :from_wallet,
          :from_token,
          :from_wallet,
          :from_user,
          :to_wallet,
          :to_token,
          :to_user
        ])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_create_without_exchange_logs(get_test_key(), transaction)
    end
  end

  describe "/transaction.create for cross-token transactions" do
    test_with_auths "returns the created transaction" do
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
        request("/transaction.create", %{
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

    test_with_auths "returns the created transaction with an unfixed from_amount" do
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
        request("/transaction.create", %{
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

    test_with_auths "returns the created transaction with an unfixed to_amount" do
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
        request("/transaction.create", %{
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

    test_with_auths "returns the created transaction when `from_amount` and `to_amount` are equal" do
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
        request("/transaction.create", %{
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

    test_with_auths "create a transaction with exchange_account_id" do
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
        request("/transaction.create", %{
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

    test_with_auths "create a transaction with exchange_wallet_address" do
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
        request("/transaction.create", %{
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

    test_with_auths "create a transaction with exchange wallet also being the `from` wallet" do
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
        request("/transaction.create", %{
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

    test_with_auths "creates a transaction with exchange wallet also being the `to` wallet" do
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
        request("/transaction.create", %{
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

    test_with_auths "returns an error when doing a cross-token transaction with invalid rate" do
      {:ok, user_1} = :user |> params_for() |> User.insert()
      {:ok, user_2} = :user |> params_for() |> User.insert()

      wallet_1 = User.get_primary_wallet(user_1)
      wallet_2 = User.get_primary_wallet(user_2)

      token_1 = insert(:token)
      token_2 = insert(:token)

      _pair = insert(:exchange_pair, from_token: token_1, to_token: token_2, rate: 2)

      response =
        request("/transaction.create", %{
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

    test_with_auths "returns an error when doing a cross-token transaction with invalid rate and same amounts" do
      {:ok, user_1} = :user |> params_for() |> User.insert()
      {:ok, user_2} = :user |> params_for() |> User.insert()

      wallet_1 = User.get_primary_wallet(user_1)
      wallet_2 = User.get_primary_wallet(user_2)

      token_1 = insert(:token)
      token_2 = insert(:token)

      _pair = insert(:exchange_pair, from_token: token_1, to_token: token_2, rate: 2)

      response =
        request("/transaction.create", %{
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

    test_with_auths "returns an error when doing a cross-token transaction with invalid exchange_account_id" do
      {:ok, user_1} = :user |> params_for() |> User.insert()
      {:ok, user_2} = :user |> params_for() |> User.insert()

      wallet_1 = User.get_primary_wallet(user_1)
      wallet_2 = User.get_primary_wallet(user_2)

      token_1 = insert(:token)
      token_2 = insert(:token)

      pair = insert(:exchange_pair, from_token: token_1, to_token: token_2, rate: 2)

      response =
        request("/transaction.create", %{
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

    test_with_auths "returns user:same_address when `from` and `to` and exchange wallet are the same address" do
      exchange_account = Account.get_master_account()
      wallet = Account.get_primary_wallet(exchange_account)

      token_1 = insert(:token)
      token_2 = insert(:token)

      mint!(token_1)
      mint!(token_2)

      pair = insert(:exchange_pair, from_token: token_1, to_token: token_2, rate: 2)

      response =
        request("/transaction.create", %{
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

    defp assert_create_with_exchange_logs(logs, originator, target) do
      assert Enum.count(logs) == 2

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: originator,
        target: target,
        changes: %{
          "from" => target.from_wallet.address,
          "from_token_uuid" => target.from_token.uuid,
          "from_user_uuid" => target.from_user.uuid,
          "to" => target.to_wallet.address,
          "to_token_uuid" => target.to_token.uuid,
          "to_user_uuid" => target.to_user.uuid,
          "from_amount" => target.from_amount,
          "idempotency_token" => target.idempotency_token,
          "to_amount" => target.to_amount,
          "calculated_at" => DateFormatter.to_iso8601(target.calculated_at),
          "exchange_account_uuid" => target.exchange_account.uuid,
          "exchange_pair_uuid" => target.exchange_pair.uuid,
          "exchange_wallet_address" => target.exchange_wallet.address,
          "rate" => target.rate
        },
        encrypted_changes: %{
          "payload" => %{
            "from_address" => target.from_wallet.address,
            "to_address" => target.to_wallet.address,
            "idempotency_token" => target.idempotency_token,
            "exchange_account_id" => target.exchange_account.id,
            "from_amount" => target.from_amount,
            "from_token_id" => target.from_token.id,
            "to_amount" => target.to_amount,
            "to_token_id" => target.to_token.id
          }
        }
      )

      logs
      |> Enum.at(1)
      |> assert_activity_log(
        action: "update",
        originator: :system,
        target: target,
        changes: %{
          "local_ledger_uuid" => target.local_ledger_uuid,
          "status" => "confirmed"
        },
        encrypted_changes: %{}
      )
    end

    test "generates an activity log for an admin request" do
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

      timestamp = DateTime.utc_now()

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

      transaction =
        response["data"]["id"]
        |> Transaction.get()
        |> Repo.preload([
          :from_wallet,
          :from_token,
          :from_user,
          :to_wallet,
          :to_token,
          :to_user,
          :exchange_pair,
          :exchange_account,
          :exchange_wallet
        ])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_create_with_exchange_logs(get_test_admin(), transaction)
    end

    test "generates an activity log for a provider request" do
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

      timestamp = DateTime.utc_now()

      response =
        provider_request("/transaction.create", %{
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

      transaction =
        response["data"]["id"]
        |> Transaction.get()
        |> Repo.preload([
          :from_wallet,
          :from_token,
          :from_user,
          :to_wallet,
          :to_token,
          :to_user,
          :exchange_pair,
          :exchange_account,
          :exchange_wallet
        ])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_create_with_exchange_logs(get_test_key(), transaction)
    end
  end
end
