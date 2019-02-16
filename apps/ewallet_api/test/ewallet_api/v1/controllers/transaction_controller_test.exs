# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWalletAPI.V1.TransactionControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias Ecto.UUID
  alias EWallet.BalanceFetcher
  alias EWalletDB.{Account, Transaction, User}

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

  describe "/me.get_transactions" do
    test "returns all the transactions for the current user", meta do
      response =
        client_request("/me.get_transactions", %{
          "sort_by" => "created_at"
        })

      assert response["data"]["data"] |> length() == 4

      ids =
        Enum.map(response["data"]["data"], fn t ->
          t["id"]
        end)

      assert Enum.member?(ids, meta.transaction_1.id)
      assert Enum.member?(ids, meta.transaction_2.id)
      assert Enum.member?(ids, meta.transaction_3.id)
      assert Enum.member?(ids, meta.transaction_4.id)
    end

    test "ignores search terms if both from and to are provided and
          address does not belong to user",
         meta do
      response =
        client_request("/me.get_transactions", %{
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "search_terms" => %{
            "from" => meta.wallet_2.address,
            "to" => meta.wallet_2.address
          }
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

    test "returns only the transactions sent to a specific wallet with nil from", meta do
      response =
        client_request("/me.get_transactions", %{
          "search_terms" => %{
            "from" => nil,
            "to" => meta.wallet_3.address
          }
        })

      assert response["data"]["data"] |> length() == 1

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transaction_3.id
             ]
    end

    test "returns only the transactions sent to a specific wallet", meta do
      response =
        client_request("/me.get_transactions", %{
          "search_terms" => %{
            "to" => meta.wallet_3.address
          }
        })

      assert response["data"]["data"] |> length() == 1

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transaction_3.id
             ]
    end

    test "returns all transactions for the current user sorted", meta do
      response =
        client_request("/me.get_transactions", %{
          "sort_by" => "created_at",
          "sort_dir" => "desc"
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

    test "returns all transactions for the current user filtered", meta do
      response =
        client_request("/me.get_transactions", %{
          "search_terms" => %{"status" => "pending"}
        })

      assert response["data"]["data"] |> length() == 1

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transaction_4.id
             ]
    end

    test "returns all transactions for the current user paginated", meta do
      response =
        client_request("/me.get_transactions", %{
          "page" => 2,
          "per_page" => 1,
          "sort_by" => "created_at",
          "sort_dir" => "desc"
        })

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.transaction_3.id
             ]
    end
  end

  describe "/me.create_transaction" do
    test "returns idempotency error if header is not specified" do
      wallet1 = User.get_primary_wallet(get_test_user())
      wallet2 = insert(:wallet)
      token = insert(:token)

      request_data = %{
        from_address: wallet1.address,
        to_address: wallet2.address,
        token_id: token.id,
        amount: 1_000 * token.subunit_to_unit,
        metadata: %{}
      }

      response = client_request("/me.create_transaction", request_data)

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "client:invalid_parameter",
                 "description" => "Invalid parameter provided. `idempotency_token` is required.",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test "updates the wallets and returns the transaction" do
      user_1 = get_test_user()
      {:ok, user_2} = :user |> params_for() |> User.insert()
      wallet_1 = User.get_primary_wallet(user_1)
      wallet_2 = User.get_primary_wallet(user_2)

      token = insert(:token)

      set_initial_balance(%{
        address: wallet_1.address,
        token: token,
        amount: 200_000
      })

      response =
        client_request("/me.create_transaction", %{
          idempotency_token: UUID.generate(),
          from_address: wallet_1.address,
          to_address: wallet_2.address,
          token_id: token.id,
          amount: 100 * token.subunit_to_unit,
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      {:ok, b1} = BalanceFetcher.get(token.id, wallet_1)
      assert List.first(b1.balances).amount == (200_000 - 100) * token.subunit_to_unit
      {:ok, b2} = BalanceFetcher.get(token.id, wallet_2)
      assert List.first(b2.balances).amount == 100 * token.subunit_to_unit

      transaction = get_last_inserted(Transaction)

      assert response["data"]["from"]["address"] == transaction.from
      assert response["data"]["from"]["amount"] == transaction.from_amount
      assert response["data"]["from"]["account_id"] == nil
      assert response["data"]["from"]["user_id"] == user_1.id
      assert response["data"]["from"]["token_id"] == token.id

      assert response["data"]["to"]["address"] == transaction.to
      assert response["data"]["to"]["amount"] == transaction.to_amount
      assert response["data"]["to"]["account_id"] == nil
      assert response["data"]["to"]["user_id"] == user_2.id
      assert response["data"]["to"]["token_id"] == token.id
    end

    test "updates the wallets and returns the transaction with string amounts" do
      user_1 = get_test_user()
      {:ok, user_2} = :user |> params_for() |> User.insert()
      wallet_1 = User.get_primary_wallet(user_1)
      wallet_2 = User.get_primary_wallet(user_2)

      token = insert(:token)

      set_initial_balance(%{
        address: wallet_1.address,
        token: token,
        amount: 200_000
      })

      response =
        client_request("/me.create_transaction", %{
          idempotency_token: UUID.generate(),
          from_address: wallet_1.address,
          to_address: wallet_2.address,
          token_id: token.id,
          amount: "10000",
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      {:ok, b1} = BalanceFetcher.get(token.id, wallet_1)
      assert List.first(b1.balances).amount == (200_000 - 100) * token.subunit_to_unit
      {:ok, b2} = BalanceFetcher.get(token.id, wallet_2)
      assert List.first(b2.balances).amount == 100 * token.subunit_to_unit

      transaction = get_last_inserted(Transaction)

      assert response["data"]["from"]["address"] == transaction.from
      assert response["data"]["from"]["amount"] == transaction.from_amount
      assert response["data"]["from"]["account_id"] == nil
      assert response["data"]["from"]["user_id"] == user_1.id
      assert response["data"]["from"]["token_id"] == token.id

      assert response["data"]["to"]["address"] == transaction.to
      assert response["data"]["to"]["amount"] == transaction.to_amount
      assert response["data"]["to"]["account_id"] == nil
      assert response["data"]["to"]["user_id"] == user_2.id
      assert response["data"]["to"]["token_id"] == token.id
    end

    test "returns a 'same_address' error when the addresses are the same" do
      wallet = User.get_primary_wallet(get_test_user())
      token = insert(:token)

      response =
        client_request("/me.create_transaction", %{
          idempotency_token: UUID.generate(),
          from_address: wallet.address,
          to_address: wallet.address,
          token_id: token.id,
          amount: 100_000 * token.subunit_to_unit
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "transaction:same_address",
                 "description" =>
                   "Found identical addresses in senders and receivers: #{wallet.address}.",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test "returns insufficient_funds when the user is too poor :~(" do
      wallet1 = User.get_primary_wallet(get_test_user())
      wallet2 = insert(:wallet)
      token = insert(:token)

      response =
        client_request("/me.create_transaction", %{
          idempotency_token: UUID.generate(),
          from_address: wallet1.address,
          to_address: wallet2.address,
          token_id: token.id,
          amount: 100_000 * token.subunit_to_unit
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "transaction:insufficient_funds",
                 "description" =>
                   "The specified wallet (#{wallet1.address}) does not " <>
                     "contain enough funds. Available: 0 #{token.id} - " <>
                     "Attempted debit: 100000 #{token.id}",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test "returns from_address_not_found when no wallet found for the 'from_address'" do
      wallet = insert(:wallet)
      token = insert(:token)

      response =
        client_request("/me.create_transaction", %{
          idempotency_token: UUID.generate(),
          from_address: "00000000-0000-0000-0000-000000000000",
          to_address: wallet.address,
          token_id: token.id,
          amount: 100_000
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "user:from_address_not_found",
                 "description" => "No wallet found for the provided from_address.",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test "returns a from_address_mismatch error if 'from_address' does not belong to the user" do
      wallet1 = insert(:wallet)
      wallet2 = insert(:wallet)
      token = insert(:token)

      response =
        client_request("/me.create_transaction", %{
          idempotency_token: UUID.generate(),
          from_address: wallet1.address,
          to_address: wallet2.address,
          token_id: token.id,
          amount: 100_000
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "user:from_address_mismatch",
                 "description" =>
                   "The provided wallet address does not belong to the current user.",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test "returns to_address_not_found when the to wallet is not found" do
      wallet = User.get_primary_wallet(get_test_user())
      token = insert(:token)

      response =
        client_request("/me.create_transaction", %{
          idempotency_token: UUID.generate(),
          from_address: wallet.address,
          to_address: "00000000-0000-0000-0000-000000000000",
          token_id: token.id,
          amount: 100_000
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "wallet:to_address_not_found",
                 "description" => "No wallet found for the provided to_address.",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test "returns token_not_found when the token is not found" do
      wallet1 = User.get_primary_wallet(get_test_user())
      wallet2 = insert(:wallet)

      response =
        client_request("/me.create_transaction", %{
          idempotency_token: UUID.generate(),
          from_address: wallet1.address,
          to_address: wallet2.address,
          token_id: "BTC:456",
          amount: 100_000
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

    test "takes primary wallet if 'from_address' is not specified" do
      wallet1 = User.get_primary_wallet(get_test_user())
      wallet2 = insert(:wallet)
      token = insert(:token)

      set_initial_balance(%{
        address: wallet1.address,
        token: token,
        amount: 200_000
      })

      client_request("/me.create_transaction", %{
        idempotency_token: UUID.generate(),
        to_address: wallet2.address,
        token_id: token.id,
        amount: 100_000
      })

      transaction = get_last_inserted(Transaction)
      assert transaction.from == wallet1.address
    end

    test "returns an invalid_parameter error if a parameter is missing" do
      response =
        client_request("/me.create_transaction", %{
          idempotency_token: UUID.generate(),
          token_id: "an_id",
          amount: 100_000
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "client:invalid_parameter",
                 "description" => "Invalid parameter provided.",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test "generates an activity log" do
      user_1 = get_test_user()
      {:ok, user_2} = :user |> params_for() |> User.insert()
      wallet_1 = User.get_primary_wallet(user_1)
      wallet_2 = User.get_primary_wallet(user_2)

      token = insert(:token)

      set_initial_balance(%{
        address: wallet_1.address,
        token: token,
        amount: 200_000
      })

      timestamp = DateTime.utc_now()

      response =
        client_request("/me.create_transaction", %{
          idempotency_token: UUID.generate(),
          from_address: wallet_1.address,
          to_address: wallet_2.address,
          token_id: token.id,
          amount: 100 * token.subunit_to_unit,
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      assert response["success"] == true

      transaction = Transaction.get(response["data"]["id"])
      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 2

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: user_1,
        target: transaction,
        changes: %{
          "from" => wallet_1.address,
          "from_amount" => 10_000,
          "from_token_uuid" => token.uuid,
          "from_user_uuid" => user_1.uuid,
          "idempotency_token" => transaction.idempotency_token,
          "metadata" => %{"something" => "interesting"},
          "to" => wallet_2.address,
          "to_amount" => 10_000,
          "to_token_uuid" => token.uuid,
          "to_user_uuid" => user_2.uuid
        },
        encrypted_changes: %{
          "encrypted_metadata" => %{"something" => "secret"},
          "payload" => %{
            "amount" => 10_000,
            "encrypted_metadata" => %{"something" => "secret"},
            "from_address" => wallet_1.address,
            "from_user_id" => user_1.id,
            "idempotency_token" => transaction.idempotency_token,
            "metadata" => %{"something" => "interesting"},
            "to_address" => wallet_2.address,
            "token_id" => token.id
          }
        }
      )

      logs
      |> Enum.at(1)
      |> assert_activity_log(
        action: "update",
        originator: :system,
        target: transaction,
        changes: %{"local_ledger_uuid" => transaction.local_ledger_uuid, "status" => "confirmed"},
        encrypted_changes: %{}
      )
    end
  end

  describe "/me.create_transaction with exchange" do
    test "updates the wallets and returns the transaction after exchange with same token" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet_1 = User.get_primary_wallet(get_test_user())
      wallet_2 = Account.get_primary_wallet(account)
      token_1 = insert(:token, subunit_to_unit: 100)

      mint!(token_1)

      set_initial_balance(%{
        address: wallet_1.address,
        token: token_1,
        amount: 200_000
      })

      response =
        client_request("/me.create_transaction", %{
          idempotency_token: UUID.generate(),
          to_account_id: account.id,
          token_id: token_1.id,
          amount: 1_000 * token_1.subunit_to_unit
        })

      assert response["success"] == true
      assert response["data"]["object"] == "transaction"

      assert response["data"]["from"]["address"] == wallet_1.address
      assert response["data"]["from"]["amount"] == 1_000 * token_1.subunit_to_unit
      assert response["data"]["from"]["token_id"] == token_1.id

      assert response["data"]["to"]["address"] == wallet_2.address
      assert response["data"]["to"]["amount"] == 1_000 * token_1.subunit_to_unit
      assert response["data"]["to"]["token_id"] == token_1.id

      {:ok, b1} = BalanceFetcher.get(token_1.id, wallet_1)
      assert List.first(b1.balances).amount == (200_000 - 1_000) * token_1.subunit_to_unit
      {:ok, b2} = BalanceFetcher.get(token_1.id, wallet_2)
      assert List.first(b2.balances).amount == 1_000 * token_1.subunit_to_unit
    end

    test "prevents exchange in the client API" do
      wallet_1 = User.get_primary_wallet(get_test_user())
      wallet_2 = insert(:wallet)
      token_1 = insert(:token, subunit_to_unit: 100)
      token_2 = insert(:token, subunit_to_unit: 1000)

      mint!(token_1)
      mint!(token_2)

      _pair = insert(:exchange_pair, from_token: token_1, to_token: token_2, rate: 2)

      set_initial_balance(%{
        address: wallet_1.address,
        token: token_1,
        amount: 200_000
      })

      response =
        client_request("/me.create_transaction", %{
          idempotency_token: UUID.generate(),
          from_address: wallet_1.address,
          to_address: wallet_2.address,
          from_token_id: token_1.id,
          to_token_id: token_2.id,
          to_amount: 2_000 * token_2.subunit_to_unit,
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `token_id` or a pair of `from_token_id` and `to_token_id` is required."
    end
  end
end
