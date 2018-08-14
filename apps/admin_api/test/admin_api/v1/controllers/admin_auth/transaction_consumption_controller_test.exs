defmodule AdminAPI.V1.AdminAuth.TransactionConsumptionControllerTest do
  use AdminAPI.ConnCase, async: true

  alias EWalletDB.{
    Repo,
    TransactionRequest,
    TransactionConsumption,
    User,
    Transaction,
    Account,
    AccountUser
  }

  alias EWallet.{TestEndpoint, BalanceFetcher}
  alias EWallet.Web.{Date, V1.WebsocketResponseSerializer}
  alias Phoenix.Socket.Broadcast

  alias EWallet.Web.V1.{
    AccountSerializer,
    TokenSerializer,
    TransactionRequestSerializer,
    TransactionSerializer
  }

  alias EWallet.TransactionConsumptionScheduler
  alias AdminAPI.V1.Endpoint

  setup do
    {:ok, _} = TestEndpoint.start_link()

    account = Account.get_master_account()
    {:ok, alice} = :user |> params_for() |> User.insert()
    bob = get_test_user()
    {:ok, _} = AccountUser.link(account.uuid, bob.uuid)

    %{
      account: account,
      token: insert(:token),
      alice: alice,
      bob: bob,
      account_wallet: Account.get_primary_wallet(account),
      alice_wallet: User.get_primary_wallet(alice),
      bob_wallet: User.get_primary_wallet(bob)
    }
  end

  describe "/transaction_consumption.all" do
    setup do
      user = get_test_user()
      account = Account.get_master_account()

      tc_1 = insert(:transaction_consumption, user_uuid: user.uuid, status: "pending")
      tc_2 = insert(:transaction_consumption, account_uuid: account.uuid, status: "pending")
      tc_3 = insert(:transaction_consumption, account_uuid: account.uuid, status: "confirmed")

      %{
        user: user,
        tc_1: tc_1,
        tc_2: tc_2,
        tc_3: tc_3
      }
    end

    test "returns all the transaction_consumptions", meta do
      response =
        admin_user_request("/transaction_consumption.all", %{
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      transfers = [
        meta.tc_1,
        meta.tc_2,
        meta.tc_3
      ]

      assert length(response["data"]["data"]) == length(transfers)

      # All transfers made during setup should exist in the response
      assert Enum.all?(transfers, fn transfer ->
               Enum.any?(response["data"]["data"], fn data ->
                 transfer.id == data["id"]
               end)
             end)
    end

    test "returns all the transaction_consumptions for a specific status", meta do
      response =
        admin_user_request("/transaction_consumption.all", %{
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "search_terms" => %{
            "status" => "pending"
          }
        })

      assert response["data"]["data"] |> length() == 2

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.tc_1.id,
               meta.tc_2.id
             ]
    end

    test "returns all transaction_consumptions filtered", meta do
      response =
        admin_user_request("/transaction_consumption.all", %{
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "search_term" => "pending"
        })

      assert response["data"]["data"] |> length() == 2

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.tc_1.id,
               meta.tc_2.id
             ]
    end

    test "returns all transaction_consumptions sorted and paginated", meta do
      response =
        admin_user_request("/transaction_consumption.all", %{
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
               meta.tc_1.id,
               meta.tc_2.id
             ]
    end
  end

  describe "/account.get_transaction_consumptions" do
    setup do
      user = get_test_user()
      account = Account.get_master_account()

      tc_1 = insert(:transaction_consumption, user_uuid: user.uuid, status: "pending")
      tc_2 = insert(:transaction_consumption, account_uuid: account.uuid, status: "pending")
      tc_3 = insert(:transaction_consumption, account_uuid: account.uuid, status: "confirmed")

      %{
        user: user,
        account: account,
        tc_1: tc_1,
        tc_2: tc_2,
        tc_3: tc_3
      }
    end

    test "returns :invalid_parameter when account id is not provided" do
      response =
        admin_user_request("/account.get_transaction_consumptions", %{
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      assert response == %{
               "data" => %{
                 "code" => "client:invalid_parameter",
                 "description" => "Parameter 'id' is required.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }
    end

    test "returns :account_id_not_found when id is not provided" do
      response =
        admin_user_request("/account.get_transaction_consumptions", %{
          "id" => "fake",
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "messages" => nil,
                 "object" => "error",
                 "code" => "unauthorized",
                 "description" => "You are not allowed to perform the requested operation"
               }
             }
    end

    test "returns all the transaction_consumptions for an account", meta do
      response =
        admin_user_request("/account.get_transaction_consumptions", %{
          "id" => meta.account.id,
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      transfers = [
        meta.tc_1,
        meta.tc_2,
        meta.tc_3
      ]

      assert length(response["data"]["data"]) == 3

      # All transfers made during setup should exist in the response
      assert Enum.all?(transfers, fn transfer ->
               Enum.any?(response["data"]["data"], fn data ->
                 transfer.id == data["id"]
               end)
             end)
    end

    test "returns all the transaction_consumptions for a specific status", meta do
      response =
        admin_user_request("/account.get_transaction_consumptions", %{
          "id" => meta.account.id,
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "search_terms" => %{
            "status" => "pending"
          }
        })

      assert response["data"]["data"] |> length() == 2

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.tc_1.id,
               meta.tc_2.id
             ]
    end

    test "returns all transaction_consumptions sorted and paginated", meta do
      response =
        admin_user_request("/account.get_transaction_consumptions", %{
          "id" => meta.account.id,
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
               meta.tc_1.id,
               meta.tc_2.id
             ]
    end
  end

  describe "/user.get_transaction_consumptions" do
    setup do
      user = get_test_user()
      account = Account.get_master_account()

      tc_1 = insert(:transaction_consumption, account_uuid: account.uuid, status: "pending")
      tc_2 = insert(:transaction_consumption, user_uuid: user.uuid, status: "pending")
      tc_3 = insert(:transaction_consumption, user_uuid: user.uuid, status: "confirmed")

      %{
        user: user,
        account: account,
        tc_1: tc_1,
        tc_2: tc_2,
        tc_3: tc_3
      }
    end

    test "returns :invalid_parameter when id or provider_user_id is not provided" do
      response =
        admin_user_request("/user.get_transaction_consumptions", %{
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      assert response == %{
               "data" => %{
                 "code" => "client:invalid_parameter",
                 "description" => "Parameter 'user_id' or 'provider_user_id' is required.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }
    end

    test "returns :id_not_found when id is not valid" do
      response =
        admin_user_request("/user.get_transaction_consumptions", %{
          "id" => "fake",
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "messages" => nil,
                 "object" => "error",
                 "code" => "user:id_not_found",
                 "description" => "There is no user corresponding to the provided id"
               }
             }
    end

    test "returns :provider_user_id_not_found when provider_user_id is not valid" do
      response =
        admin_user_request("/user.get_transaction_consumptions", %{
          "provider_user_id" => "fake",
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "messages" => nil,
                 "object" => "error",
                 "code" => "user:provider_user_id_not_found",
                 "description" =>
                   "There is no user corresponding to the provided provider_user_id"
               }
             }
    end

    test "returns all the transaction_consumptions for a user when given an id", meta do
      response =
        admin_user_request("/user.get_transaction_consumptions", %{
          "id" => meta.user.id,
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      assert length(response["data"]["data"]) == 2

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.tc_2.id,
               meta.tc_3.id
             ]
    end

    test "returns all the transaction_consumptions for a user when given a user_id", meta do
      response =
        admin_user_request("/user.get_transaction_consumptions", %{
          "user_id" => meta.user.id,
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      assert length(response["data"]["data"]) == 2

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.tc_2.id,
               meta.tc_3.id
             ]
    end

    test "returns all the transaction_consumptions for a user when given a provider_user_id",
         meta do
      response =
        admin_user_request("/user.get_transaction_consumptions", %{
          "provider_user_id" => meta.user.provider_user_id,
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      assert length(response["data"]["data"]) == 2

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.tc_2.id,
               meta.tc_3.id
             ]
    end

    test "returns all the transaction_consumptions for a specific status", meta do
      response =
        admin_user_request("/user.get_transaction_consumptions", %{
          "user_id" => meta.user.id,
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "search_terms" => %{
            "status" => "pending"
          }
        })

      assert response["data"]["data"] |> length() == 1

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.tc_2.id
             ]
    end

    test "returns all transaction_consumptions sorted and paginated", meta do
      response =
        admin_user_request("/user.get_transaction_consumptions", %{
          "user_id" => meta.user.id,
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
               meta.tc_2.id,
               meta.tc_3.id
             ]
    end
  end

  describe "/transaction_request.get_transaction_consumptions" do
    setup do
      account = insert(:account)
      transaction_request = insert(:transaction_request)

      tc_1 = insert(:transaction_consumption, account_uuid: account.uuid, status: "pending")

      tc_2 =
        insert(
          :transaction_consumption,
          transaction_request_uuid: transaction_request.uuid,
          status: "pending"
        )

      tc_3 =
        insert(
          :transaction_consumption,
          transaction_request_uuid: transaction_request.uuid,
          status: "confirmed"
        )

      %{
        transaction_request: transaction_request,
        tc_1: tc_1,
        tc_2: tc_2,
        tc_3: tc_3
      }
    end

    test "returns :invalid_parameter when formatted_transaction_request_id is not provided" do
      response =
        admin_user_request("/transaction_request.get_transaction_consumptions", %{
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      assert response == %{
               "data" => %{
                 "code" => "client:invalid_parameter",
                 "description" => "Parameter 'formatted_transaction_request_id' is required.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }
    end

    test "returns :unauthorized when formatted_transaction_request_id is not valid" do
      response =
        admin_user_request("/transaction_request.get_transaction_consumptions", %{
          "formatted_transaction_request_id" => "fake",
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "unauthorized",
                 "messages" => nil,
                 "object" => "error",
                 "description" => "You are not allowed to perform the requested operation"
               }
             }
    end

    test "returns all the transaction_consumptions for a transaction_request", meta do
      response =
        admin_user_request("/transaction_request.get_transaction_consumptions", %{
          "formatted_transaction_request_id" => meta.transaction_request.id,
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      assert length(response["data"]["data"]) == 2

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.tc_2.id,
               meta.tc_3.id
             ]
    end

    test "returns all the transaction_consumptions for a specific status", meta do
      response =
        admin_user_request("/transaction_request.get_transaction_consumptions", %{
          "formatted_transaction_request_id" => meta.transaction_request.id,
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "search_terms" => %{
            "status" => "pending"
          }
        })

      assert response["data"]["data"] |> length() == 1

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.tc_2.id
             ]
    end

    test "returns all transaction_consumptions sorted and paginated", meta do
      response =
        admin_user_request("/transaction_request.get_transaction_consumptions", %{
          "formatted_transaction_request_id" => meta.transaction_request.id,
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
               meta.tc_2.id,
               meta.tc_3.id
             ]
    end
  end

  describe "/wallet.get_transaction_consumptions" do
    setup do
      account = insert(:account)
      wallet = insert(:wallet)
      {:ok, _} = AccountUser.link(account.uuid, wallet.user_uuid)

      tc_1 = insert(:transaction_consumption, account_uuid: account.uuid, status: "pending")

      tc_2 =
        insert(
          :transaction_consumption,
          wallet_address: wallet.address,
          status: "pending"
        )

      tc_3 =
        insert(
          :transaction_consumption,
          wallet_address: wallet.address,
          status: "confirmed"
        )

      %{
        wallet: wallet,
        tc_1: tc_1,
        tc_2: tc_2,
        tc_3: tc_3
      }
    end

    test "returns :invalid_parameter when address is not provided" do
      response =
        admin_user_request("/wallet.get_transaction_consumptions", %{
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      assert response == %{
               "data" => %{
                 "code" => "client:invalid_parameter",
                 "description" => "Parameter 'address' is required.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }
    end

    test "returns :unauthorized when address is not provided" do
      response =
        admin_user_request("/wallet.get_transaction_consumptions", %{
          "address" => "fake-0000-0000-0000",
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "unauthorized",
                 "messages" => nil,
                 "object" => "error",
                 "description" => "You are not allowed to perform the requested operation"
               }
             }
    end

    test "returns all the transaction_consumptions for a wallet", meta do
      response =
        admin_user_request("/wallet.get_transaction_consumptions", %{
          "address" => meta.wallet.address,
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      assert length(response["data"]["data"]) == 2

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.tc_2.id,
               meta.tc_3.id
             ]
    end

    test "returns all the transaction_consumptions for a specific status", meta do
      response =
        admin_user_request("/wallet.get_transaction_consumptions", %{
          "address" => meta.wallet.address,
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "search_terms" => %{
            "status" => "pending"
          }
        })

      assert response["data"]["data"] |> length() == 1

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               meta.tc_2.id
             ]
    end

    test "returns all transaction_consumptions sorted and paginated", meta do
      response =
        admin_user_request("/wallet.get_transaction_consumptions", %{
          "address" => meta.wallet.address,
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
               meta.tc_2.id,
               meta.tc_3.id
             ]
    end
  end

  describe "/transaction_consumption.get" do
    test "returns the transaction consumption" do
      transaction_consumption = insert(:transaction_consumption)

      response =
        admin_user_request("/transaction_consumption.get", %{
          id: transaction_consumption.id
        })

      assert response["success"] == true
      assert response["data"]["id"] == transaction_consumption.id
    end

    test "returns an error when the consumption ID is not found" do
      response =
        admin_user_request("/transaction_consumption.get", %{
          id: "123"
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "transaction_consumption:transaction_consumption_not_found",
                 "description" =>
                   "There is no transaction consumption corresponding to the provided ID.",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end
  end

  describe "/transaction_request.consume" do
    test "consumes the request and transfers the appropriate amount of tokens", meta do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: meta.token.uuid,
          user_uuid: meta.alice.uuid,
          wallet: meta.alice_wallet,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      set_initial_balance(%{
        address: meta.bob_wallet.address,
        token: meta.token,
        amount: 150_000
      })

      response =
        admin_user_request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil,
          account_id: meta.account.id
        })

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transaction = Repo.get(Transaction, inserted_consumption.transaction_uuid)
      request = TransactionRequest.get(transaction_request.id, preload: [:token])

      assert response == %{
               "success" => true,
               "version" => "1",
               "data" => %{
                 "address" => meta.account_wallet.address,
                 "amount" => nil,
                 "estimated_consumption_amount" => 100_000 * meta.token.subunit_to_unit,
                 "estimated_request_amount" => 100_000 * meta.token.subunit_to_unit,
                 "finalized_request_amount" => 100_000 * meta.token.subunit_to_unit,
                 "finalized_consumption_amount" => 100_000 * meta.token.subunit_to_unit,
                 "correlation_id" => nil,
                 "id" => inserted_consumption.id,
                 "socket_topic" => "transaction_consumption:#{inserted_consumption.id}",
                 "idempotency_token" => "123",
                 "object" => "transaction_consumption",
                 "status" => "confirmed",
                 "token_id" => meta.token.id,
                 "token" => meta.token |> TokenSerializer.serialize() |> stringify_keys(),
                 "transaction_request_id" => transaction_request.id,
                 "transaction_request" =>
                   request |> TransactionRequestSerializer.serialize() |> stringify_keys(),
                 "transaction_id" => inserted_transaction.id,
                 "transaction" =>
                   inserted_transaction |> TransactionSerializer.serialize() |> stringify_keys(),
                 "user_id" => nil,
                 "user" => nil,
                 "account_id" => meta.account.id,
                 "account" => meta.account |> AccountSerializer.serialize() |> stringify_keys(),
                 "exchange_account" => nil,
                 "exchange_account_id" => nil,
                 "exchange_wallet" => nil,
                 "exchange_wallet_address" => nil,
                 "metadata" => %{},
                 "encrypted_metadata" => %{},
                 "expiration_date" => nil,
                 "created_at" => Date.to_iso8601(inserted_consumption.inserted_at),
                 "approved_at" => Date.to_iso8601(inserted_consumption.approved_at),
                 "rejected_at" => Date.to_iso8601(inserted_consumption.rejected_at),
                 "confirmed_at" => Date.to_iso8601(inserted_consumption.confirmed_at),
                 "failed_at" => Date.to_iso8601(inserted_consumption.failed_at),
                 "expired_at" => nil
               }
             }

      assert inserted_transaction.from_amount == 100_000 * meta.token.subunit_to_unit
      assert inserted_transaction.from_token_uuid == meta.token.uuid
      assert inserted_transaction.to_amount == 100_000 * meta.token.subunit_to_unit
      assert inserted_transaction.to_token_uuid == meta.token.uuid
      assert inserted_transaction.to == meta.alice_wallet.address
      assert inserted_transaction.from == meta.account_wallet.address
      assert inserted_transaction.local_ledger_uuid != nil
    end

    test "fails to consume when trying to send from a burn wallet", meta do
      burn_wallet = Account.get_default_burn_wallet(meta.account)

      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          token_uuid: meta.token.uuid,
          wallet: burn_wallet,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      response =
        admin_user_request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil,
          user_id: meta.bob.id
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided `from` can't be the address of a burn wallet."

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      assert inserted_consumption.error_code == "client:invalid_parameter"

      assert inserted_consumption.error_description ==
               "Invalid parameter provided `from` can't be the address of a burn wallet."
    end

    test "consumes the request and transfers the appropriate amount of tokens with string",
         meta do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: meta.token.uuid,
          user_uuid: meta.alice.uuid,
          wallet: meta.alice_wallet,
          amount: nil
        )

      set_initial_balance(%{
        address: meta.bob_wallet.address,
        token: meta.token,
        amount: 100_000 * meta.token.subunit_to_unit
      })

      response =
        admin_user_request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: "10000000",
          address: nil,
          metadata: nil,
          token_id: nil,
          account_id: meta.account.id
        })

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transaction = Repo.get(Transaction, inserted_consumption.transaction_uuid)
      request = TransactionRequest.get(transaction_request.id, preload: [:token])

      assert response == %{
               "success" => true,
               "version" => "1",
               "data" => %{
                 "address" => meta.account_wallet.address,
                 "amount" => 100_000 * meta.token.subunit_to_unit,
                 "estimated_consumption_amount" => 100_000 * meta.token.subunit_to_unit,
                 "estimated_request_amount" => 100_000 * meta.token.subunit_to_unit,
                 "finalized_request_amount" => 100_000 * meta.token.subunit_to_unit,
                 "finalized_consumption_amount" => 100_000 * meta.token.subunit_to_unit,
                 "correlation_id" => nil,
                 "id" => inserted_consumption.id,
                 "socket_topic" => "transaction_consumption:#{inserted_consumption.id}",
                 "idempotency_token" => "123",
                 "object" => "transaction_consumption",
                 "status" => "confirmed",
                 "token_id" => meta.token.id,
                 "token" => meta.token |> TokenSerializer.serialize() |> stringify_keys(),
                 "transaction_request_id" => transaction_request.id,
                 "transaction_request" =>
                   request |> TransactionRequestSerializer.serialize() |> stringify_keys(),
                 "transaction_id" => inserted_transaction.id,
                 "transaction" =>
                   inserted_transaction |> TransactionSerializer.serialize() |> stringify_keys(),
                 "user_id" => nil,
                 "user" => nil,
                 "account_id" => meta.account.id,
                 "account" => meta.account |> AccountSerializer.serialize() |> stringify_keys(),
                 "exchange_account" => nil,
                 "exchange_account_id" => nil,
                 "exchange_wallet" => nil,
                 "exchange_wallet_address" => nil,
                 "metadata" => %{},
                 "encrypted_metadata" => %{},
                 "expiration_date" => nil,
                 "created_at" => Date.to_iso8601(inserted_consumption.inserted_at),
                 "approved_at" => Date.to_iso8601(inserted_consumption.approved_at),
                 "rejected_at" => Date.to_iso8601(inserted_consumption.rejected_at),
                 "confirmed_at" => Date.to_iso8601(inserted_consumption.confirmed_at),
                 "failed_at" => Date.to_iso8601(inserted_consumption.failed_at),
                 "expired_at" => nil
               }
             }

      assert inserted_transaction.from_amount == 100_000 * meta.token.subunit_to_unit
      assert inserted_transaction.from_token_uuid == meta.token.uuid
      assert inserted_transaction.to_amount == 100_000 * meta.token.subunit_to_unit
      assert inserted_transaction.to_token_uuid == meta.token.uuid
      assert inserted_transaction.to == meta.alice_wallet.address
      assert inserted_transaction.from == meta.account_wallet.address
      assert inserted_transaction.local_ledger_uuid != nil
    end

    test "consumes the request and transfers with exchange details in request",
         meta do
      token_2 = insert(:token)
      mint!(token_2)
      _pair = insert(:exchange_pair, from_token: meta.token, to_token: token_2, rate: 2)

      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          token_uuid: meta.token.uuid,
          user_uuid: meta.alice.uuid,
          wallet: meta.alice_wallet,
          amount: 100_000 * meta.token.subunit_to_unit,
          exchange_account_uuid: meta.account.uuid,
          exchange_wallet_address: meta.account_wallet.address
        )

      set_initial_balance(%{
        address: meta.alice_wallet.address,
        token: meta.token,
        amount: 150_000
      })

      response =
        admin_user_request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: token_2.id,
          user_id: meta.bob.id
        })

      assert response["success"] == true

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transaction = Repo.get(Transaction, inserted_consumption.transaction_uuid)

      assert response["data"]["amount"] == nil
      assert response["data"]["finalized_request_amount"] == 100_000 * meta.token.subunit_to_unit
      assert response["data"]["finalized_consumption_amount"] == 200_000 * token_2.subunit_to_unit
      assert response["data"]["estimated_request_amount"] == 100_000 * meta.token.subunit_to_unit
      assert response["data"]["estimated_consumption_amount"] == 200_000 * token_2.subunit_to_unit
      assert response["data"]["token_id"] == token_2.id
      assert response["data"]["address"] == meta.bob_wallet.address
      assert response["data"]["user_id"] == meta.bob.id

      assert response["data"]["transaction_request"]["amount"] ==
               100_000 * meta.token.subunit_to_unit

      assert response["data"]["transaction_request"]["token_id"] == meta.token.id
      assert response["data"]["transaction_request"]["address"] == meta.alice_wallet.address
      assert response["data"]["transaction_request"]["user_id"] == meta.alice.id

      assert inserted_transaction.from_amount == 100_000 * meta.token.subunit_to_unit
      assert inserted_transaction.from_token_uuid == meta.token.uuid
      assert inserted_transaction.to_amount == 200_000 * token_2.subunit_to_unit
      assert inserted_transaction.to_token_uuid == token_2.uuid
      assert inserted_transaction.to == meta.bob_wallet.address
      assert inserted_transaction.from == meta.alice_wallet.address
      assert inserted_transaction.local_ledger_uuid != nil

      {:ok, b1} = BalanceFetcher.get(meta.token.id, meta.alice_wallet)
      {:ok, b2} = BalanceFetcher.get(token_2.id, meta.alice_wallet)
      assert Enum.at(b1.balances, 0).amount == (150_000 - 100_000) * meta.token.subunit_to_unit
      assert Enum.at(b2.balances, 0).amount == 0

      {:ok, b1} = BalanceFetcher.get(meta.token.id, meta.bob_wallet)
      {:ok, b2} = BalanceFetcher.get(token_2.id, meta.bob_wallet)
      assert Enum.at(b1.balances, 0).amount == 0
      assert Enum.at(b2.balances, 0).amount == 100_000 * 2 * meta.token.subunit_to_unit
    end

    test "consumes the request and exchange with exchange_wallet in consumption",
         meta do
      token_2 = insert(:token)
      mint!(token_2)
      _pair = insert(:exchange_pair, from_token: meta.token, to_token: token_2, rate: 2)

      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          token_uuid: meta.token.uuid,
          user_uuid: meta.alice.uuid,
          wallet: meta.alice_wallet,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      set_initial_balance(%{
        address: meta.alice_wallet.address,
        token: meta.token,
        amount: 150_000
      })

      response =
        admin_user_request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: token_2.id,
          user_id: meta.bob.id,
          exchange_wallet_address: meta.account_wallet.address
        })

      assert response["success"] == true

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transaction = Repo.get(Transaction, inserted_consumption.transaction_uuid)

      assert response["data"]["amount"] == nil
      assert response["data"]["finalized_request_amount"] == 100_000 * meta.token.subunit_to_unit
      assert response["data"]["finalized_consumption_amount"] == 200_000 * token_2.subunit_to_unit
      assert response["data"]["estimated_request_amount"] == 100_000 * meta.token.subunit_to_unit
      assert response["data"]["estimated_consumption_amount"] == 200_000 * token_2.subunit_to_unit
      assert response["data"]["token_id"] == token_2.id
      assert response["data"]["exchange_wallet_address"] == meta.account_wallet.address
      assert response["data"]["exchange_account_id"] == meta.account.id

      assert response["data"]["transaction_request"]["amount"] ==
               100_000 * meta.token.subunit_to_unit

      assert response["data"]["transaction_request"]["token_id"] == meta.token.id
      assert response["data"]["transaction_request"]["address"] == meta.alice_wallet.address
      assert response["data"]["transaction_request"]["user_id"] == meta.alice.id
      assert response["data"]["transaction_request"]["exchange_wallet_address"] == nil
      assert response["data"]["transaction_request"]["exchange_accout_id"] == nil

      assert inserted_transaction.from_amount == 100_000 * meta.token.subunit_to_unit
      assert inserted_transaction.from_token_uuid == meta.token.uuid
      assert inserted_transaction.to_amount == 200_000 * token_2.subunit_to_unit
      assert inserted_transaction.to_token_uuid == token_2.uuid
      assert inserted_transaction.to == meta.bob_wallet.address
      assert inserted_transaction.from == meta.alice_wallet.address
      assert inserted_transaction.local_ledger_uuid != nil

      {:ok, b1} = BalanceFetcher.get(meta.token.id, meta.alice_wallet)
      {:ok, b2} = BalanceFetcher.get(token_2.id, meta.alice_wallet)
      assert Enum.at(b1.balances, 0).amount == (150_000 - 100_000) * meta.token.subunit_to_unit
      assert Enum.at(b2.balances, 0).amount == 0

      {:ok, b1} = BalanceFetcher.get(meta.token.id, meta.bob_wallet)
      {:ok, b2} = BalanceFetcher.get(token_2.id, meta.bob_wallet)
      assert Enum.at(b1.balances, 0).amount == 0
      assert Enum.at(b2.balances, 0).amount == 100_000 * 2 * meta.token.subunit_to_unit
    end

    test "consumes the request and exchange with exchange_account in consumption",
         meta do
      token_2 = insert(:token)
      mint!(token_2)
      _pair = insert(:exchange_pair, from_token: meta.token, to_token: token_2, rate: 2)

      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          token_uuid: meta.token.uuid,
          user_uuid: meta.alice.uuid,
          wallet: meta.alice_wallet,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      set_initial_balance(%{
        address: meta.alice_wallet.address,
        token: meta.token,
        amount: 150_000
      })

      response =
        admin_user_request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: token_2.id,
          user_id: meta.bob.id,
          exchange_account_id: meta.account.id
        })

      assert response["success"] == true

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transaction = Repo.get(Transaction, inserted_consumption.transaction_uuid)

      assert response["data"]["amount"] == nil
      assert response["data"]["finalized_request_amount"] == 100_000 * meta.token.subunit_to_unit
      assert response["data"]["finalized_consumption_amount"] == 200_000 * token_2.subunit_to_unit
      assert response["data"]["estimated_request_amount"] == 100_000 * meta.token.subunit_to_unit
      assert response["data"]["estimated_consumption_amount"] == 200_000 * token_2.subunit_to_unit
      assert response["data"]["token_id"] == token_2.id
      assert response["data"]["exchange_wallet_address"] == meta.account_wallet.address
      assert response["data"]["exchange_account_id"] == meta.account.id

      assert response["data"]["transaction_request"]["amount"] ==
               100_000 * meta.token.subunit_to_unit

      assert response["data"]["transaction_request"]["token_id"] == meta.token.id
      assert response["data"]["transaction_request"]["address"] == meta.alice_wallet.address
      assert response["data"]["transaction_request"]["user_id"] == meta.alice.id
      assert response["data"]["transaction_request"]["exchange_wallet_address"] == nil
      assert response["data"]["transaction_request"]["exchange_accout_id"] == nil

      assert inserted_transaction.from_amount == 100_000 * meta.token.subunit_to_unit
      assert inserted_transaction.from_token_uuid == meta.token.uuid
      assert inserted_transaction.to_amount == 200_000 * token_2.subunit_to_unit
      assert inserted_transaction.to_token_uuid == token_2.uuid
      assert inserted_transaction.to == meta.bob_wallet.address
      assert inserted_transaction.from == meta.alice_wallet.address
      assert inserted_transaction.local_ledger_uuid != nil

      {:ok, b1} = BalanceFetcher.get(meta.token.id, meta.alice_wallet)
      {:ok, b2} = BalanceFetcher.get(token_2.id, meta.alice_wallet)
      assert Enum.at(b1.balances, 0).amount == (150_000 - 100_000) * meta.token.subunit_to_unit
      assert Enum.at(b2.balances, 0).amount == 0

      {:ok, b1} = BalanceFetcher.get(meta.token.id, meta.bob_wallet)
      {:ok, b2} = BalanceFetcher.get(token_2.id, meta.bob_wallet)
      assert Enum.at(b1.balances, 0).amount == 0
      assert Enum.at(b2.balances, 0).amount == 100_000 * 2 * meta.token.subunit_to_unit
    end

    test "transfer and exchange if request and consumption specify the same exchange wallet address",
         meta do
      token_2 = insert(:token)
      mint!(token_2)
      _pair = insert(:exchange_pair, from_token: meta.token, to_token: token_2, rate: 2)

      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          token_uuid: meta.token.uuid,
          user_uuid: meta.alice.uuid,
          wallet: meta.alice_wallet,
          amount: 100_000 * meta.token.subunit_to_unit,
          exchange_account_uuid: meta.account.uuid,
          exchange_wallet_address: meta.account_wallet.address
        )

      set_initial_balance(%{
        address: meta.alice_wallet.address,
        token: meta.token,
        amount: 150_000
      })

      response =
        admin_user_request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: token_2.id,
          user_id: meta.bob.id,
          exchange_account_id: meta.account.id
        })

      assert response["success"] == true

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transaction = Repo.get(Transaction, inserted_consumption.transaction_uuid)

      assert response["data"]["amount"] == nil
      assert response["data"]["finalized_request_amount"] == 100_000 * meta.token.subunit_to_unit
      assert response["data"]["finalized_consumption_amount"] == 200_000 * token_2.subunit_to_unit
      assert response["data"]["estimated_request_amount"] == 100_000 * meta.token.subunit_to_unit
      assert response["data"]["estimated_consumption_amount"] == 200_000 * token_2.subunit_to_unit
      assert response["data"]["token_id"] == token_2.id
      assert response["data"]["exchange_wallet_address"] == meta.account_wallet.address
      assert response["data"]["exchange_account_id"] == meta.account.id

      assert response["data"]["transaction_request"]["amount"] ==
               100_000 * meta.token.subunit_to_unit

      assert response["data"]["transaction_request"]["token_id"] == meta.token.id
      assert response["data"]["transaction_request"]["address"] == meta.alice_wallet.address
      assert response["data"]["transaction_request"]["user_id"] == meta.alice.id

      assert response["data"]["transaction_request"]["exchange_wallet_address"] ==
               meta.account_wallet.address

      assert response["data"]["transaction_request"]["exchange_account_id"] == meta.account.id

      assert inserted_transaction.from_amount == 100_000 * meta.token.subunit_to_unit
      assert inserted_transaction.from_token_uuid == meta.token.uuid
      assert inserted_transaction.to_amount == 200_000 * token_2.subunit_to_unit
      assert inserted_transaction.to_token_uuid == token_2.uuid
      assert inserted_transaction.to == meta.bob_wallet.address
      assert inserted_transaction.from == meta.alice_wallet.address
      assert inserted_transaction.local_ledger_uuid != nil

      {:ok, b1} = BalanceFetcher.get(meta.token.id, meta.alice_wallet)
      {:ok, b2} = BalanceFetcher.get(token_2.id, meta.alice_wallet)
      assert Enum.at(b1.balances, 0).amount == (150_000 - 100_000) * meta.token.subunit_to_unit
      assert Enum.at(b2.balances, 0).amount == 0

      {:ok, b1} = BalanceFetcher.get(meta.token.id, meta.bob_wallet)
      {:ok, b2} = BalanceFetcher.get(token_2.id, meta.bob_wallet)
      assert Enum.at(b1.balances, 0).amount == 0
      assert Enum.at(b2.balances, 0).amount == 100_000 * 2 * meta.token.subunit_to_unit
    end

    test "fails to consume if exchange details are different and already specified in request",
         meta do
      {:ok, account_2} = :account |> params_for() |> Account.insert()
      token_2 = insert(:token)
      mint!(token_2)
      _pair = insert(:exchange_pair, from_token: meta.token, to_token: token_2, rate: 2)

      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          token_uuid: meta.token.uuid,
          user_uuid: meta.alice.uuid,
          wallet: meta.alice_wallet,
          amount: 100_000 * meta.token.subunit_to_unit,
          exchange_account_uuid: meta.account.uuid,
          exchange_wallet_address: meta.account_wallet.address
        )

      set_initial_balance(%{
        address: meta.alice_wallet.address,
        token: meta.token,
        amount: 150_000
      })

      response =
        admin_user_request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: token_2.id,
          user_id: meta.bob.id,
          exchange_account_id: account_2.id
        })

      assert response["success"] == false
      assert response["data"]["code"] == "consumption:request_already_contains_exchange_wallet"

      assert response["data"]["description"] ==
               "The transaction request for the given consumption already specify an exchange account and/or wallet."
    end

    test "fails to consume and return an insufficient funds error", meta do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: meta.token.uuid,
          user_uuid: meta.alice.uuid,
          wallet: meta.alice_wallet,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      response =
        admin_user_request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil,
          account_id: meta.account.id
        })

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transaction = Repo.get(Transaction, inserted_consumption.transaction_uuid)

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "object" => "error",
                 "messages" => nil,
                 "code" => "transaction:insufficient_funds",
                 "description" =>
                   "The specified wallet (#{meta.account_wallet.address}) does not contain enough funds. Available: 0 #{
                     meta.token.id
                   } - Attempted debit: 100000 #{meta.token.id}"
               }
             }

      assert inserted_transaction.from_amount == 100_000 * meta.token.subunit_to_unit
      assert inserted_transaction.from_token_uuid == meta.token.uuid
      assert inserted_transaction.to_amount == 100_000 * meta.token.subunit_to_unit
      assert inserted_transaction.to_token_uuid == meta.token.uuid
      assert inserted_transaction.to == meta.alice_wallet.address
      assert inserted_transaction.from == meta.account_wallet.address
      assert inserted_transaction.error_code == "insufficient_funds"
      assert inserted_transaction.error_description == nil

      assert inserted_transaction.error_data == %{
               "address" => meta.account_wallet.address,
               "amount_to_debit" => 100_000 * meta.token.subunit_to_unit,
               "current_amount" => 0,
               "token_id" => meta.token.id
             }
    end

    test "returns with preload if `embed` attribute is given", meta do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: meta.token.uuid,
          user_uuid: meta.alice.uuid,
          wallet: meta.alice_wallet,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      set_initial_balance(%{
        address: meta.bob_wallet.address,
        token: meta.token,
        amount: 150_000
      })

      response =
        admin_user_request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil,
          account_id: meta.account.id,
          embed: ["account"]
        })

      assert response["data"]["account"] != nil
    end

    test "returns same transaction request consumption when idempotency token is the same",
         meta do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: meta.token.uuid,
          account_uuid: meta.account.uuid,
          user_uuid: meta.alice.uuid,
          wallet: meta.alice_wallet,
          amount: 100_000 * meta.token.subunit_to_unit
        )

      set_initial_balance(%{
        address: meta.bob_wallet.address,
        token: meta.token,
        amount: 150_000
      })

      response =
        admin_user_request("/transaction_request.consume", %{
          idempotency_token: "1234",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil,
          account_id: meta.account.id
        })

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transaction = Repo.get(Transaction, inserted_consumption.transaction_uuid)

      assert response["success"] == true
      assert response["data"]["id"] == inserted_consumption.id

      response =
        admin_user_request("/transaction_request.consume", %{
          idempotency_token: "1234",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil,
          account_id: meta.account.id
        })

      inserted_consumption_2 = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transaction_2 = Repo.get(Transaction, inserted_consumption.transaction_uuid)

      assert response["success"] == true
      assert response["data"]["id"] == inserted_consumption_2.id
      assert inserted_consumption.uuid == inserted_consumption_2.uuid
      assert inserted_transaction.uuid == inserted_transaction_2.uuid
    end

    test "returns idempotency error if header is not specified" do
      response =
        admin_user_request("/transaction_request.consume", %{
          transaction_request_id: "123",
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil
        })

      assert response == %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "code" => "client:invalid_parameter",
                 "description" => "Invalid parameter provided",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test "sends socket confirmation when require_confirmation and approved", meta do
      mint!(meta.token)

      # Create a require_confirmation transaction request that will be consumed soon
      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          token_uuid: meta.token.uuid,
          account_uuid: meta.account.uuid,
          wallet: meta.account_wallet,
          amount: nil,
          require_confirmation: true
        )

      request_topic = "transaction_request:#{transaction_request.id}"

      # Start listening to the channels for the transaction request created above
      Endpoint.subscribe(request_topic)

      # Making the consumption, since we made the request require_confirmation, it will
      # create a pending consumption that will need to be confirmed
      response =
        admin_user_request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: 100_000 * meta.token.subunit_to_unit,
          metadata: nil,
          token_id: nil,
          provider_user_id: meta.bob.provider_user_id
        })

      consumption_id = response["data"]["id"]
      assert response["success"] == true
      assert response["data"]["status"] == "pending"
      assert response["data"]["transaction_id"] == nil

      # Retrieve what just got inserted
      inserted_consumption = TransactionConsumption.get(response["data"]["id"])

      # We check that we receive the confirmation request above in the
      # transaction request channel
      assert_receive %Phoenix.Socket.Broadcast{
        event: "transaction_consumption_request",
        topic: "transaction_request:" <> _,
        payload:
          %{
            # Ignore content
          }
      }

      # We need to know once the consumption has been approved, so let's
      # listen to the channel for it
      Endpoint.subscribe("transaction_consumption:#{consumption_id}")

      # Confirm the consumption
      response =
        admin_user_request("/transaction_consumption.approve", %{
          id: consumption_id
        })

      assert response["success"] == true
      assert response["data"]["id"] == inserted_consumption.id
      assert response["data"]["status"] == "confirmed"
      assert response["data"]["approved_at"] != nil
      assert response["data"]["confirmed_at"] != nil

      # Check that a transaction was inserted
      inserted_transaction = Repo.get_by(Transaction, id: response["data"]["transaction_id"])
      assert inserted_transaction.from_amount == 100_000 * meta.token.subunit_to_unit
      assert inserted_transaction.from_token_uuid == meta.token.uuid
      assert inserted_transaction.to_amount == 100_000 * meta.token.subunit_to_unit
      assert inserted_transaction.to_token_uuid == meta.token.uuid
      assert inserted_transaction.to == meta.bob_wallet.address
      assert inserted_transaction.from == meta.account_wallet.address
      assert inserted_transaction.local_ledger_uuid != nil

      assert_receive %Phoenix.Socket.Broadcast{
        event: "transaction_consumption_finalized",
        topic: "transaction_consumption:" <> _,
        payload:
          %{
            # Ignore content
          }
      }

      # Unsubscribe from all channels
      Endpoint.unsubscribe("transaction_request:#{transaction_request.id}")
      Endpoint.unsubscribe("transaction_consumption:#{consumption_id}")
    end

    test "sends socket confirmation when require_confirmation and approved between users", meta do
      # bob = test_user
      set_initial_balance(%{
        address: meta.bob_wallet.address,
        token: meta.token,
        amount: 1_000_000 * meta.token.subunit_to_unit
      })

      # Create a require_confirmation transaction request that will be consumed soon
      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          token_uuid: meta.token.uuid,
          account_uuid: meta.account.uuid,
          user_uuid: meta.bob.uuid,
          wallet: meta.bob_wallet,
          amount: nil,
          require_confirmation: true
        )

      request_topic = "transaction_request:#{transaction_request.id}"

      # Start listening to the channels for the transaction request created above
      Endpoint.subscribe(request_topic)

      # Making the consumption, since we made the request require_confirmation, it will
      # create a pending consumption that will need to be confirmed
      response =
        admin_user_request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: 100_000 * meta.token.subunit_to_unit,
          metadata: nil,
          token_id: nil,
          address: meta.alice_wallet.address
        })

      consumption_id = response["data"]["id"]
      assert response["success"] == true
      assert response["data"]["status"] == "pending"
      assert response["data"]["transaction_id"] == nil

      # Retrieve what just got inserted
      inserted_consumption = TransactionConsumption.get(response["data"]["id"])

      # We check that we receive the confirmation request above in the
      # transaction request channel
      assert_receive %Phoenix.Socket.Broadcast{
        event: "transaction_consumption_request",
        topic: "transaction_request:" <> _,
        payload:
          %{
            # Ignore content
          }
      }

      # We need to know once the consumption has been approved, so let's
      # listen to the channel for it
      Endpoint.subscribe("transaction_consumption:#{consumption_id}")

      # Confirm the consumption
      response =
        admin_user_request("/transaction_consumption.approve", %{
          id: consumption_id
        })

      assert response["success"] == true
      assert response["data"]["id"] == inserted_consumption.id
      assert response["data"]["status"] == "confirmed"
      assert response["data"]["approved_at"] != nil
      assert response["data"]["confirmed_at"] != nil

      # Check that a transaction was inserted
      inserted_transaction = Repo.get_by(Transaction, id: response["data"]["transaction_id"])
      assert inserted_transaction.from_amount == 100_000 * meta.token.subunit_to_unit
      assert inserted_transaction.to_amount == 100_000 * meta.token.subunit_to_unit
      assert inserted_transaction.from_token_uuid == meta.token.uuid
      assert inserted_transaction.to_token_uuid == meta.token.uuid
      assert inserted_transaction.to == meta.alice_wallet.address
      assert inserted_transaction.from == meta.bob_wallet.address
      assert inserted_transaction.local_ledger_uuid != nil

      assert_receive %Phoenix.Socket.Broadcast{
        event: "transaction_consumption_finalized",
        topic: "transaction_consumption:" <> _,
        payload:
          %{
            # Ignore content
          }
      }

      # Unsubscribe from all channels
      Endpoint.unsubscribe("transaction_request:#{transaction_request.id}")
      Endpoint.unsubscribe("transaction_consumption:#{consumption_id}")
    end

    test "sends a websocket expiration event when a consumption expires", meta do
      # bob = test_user
      set_initial_balance(%{
        address: meta.bob_wallet.address,
        token: meta.token,
        amount: 1_000_000 * meta.token.subunit_to_unit
      })

      # Create a require_confirmation transaction request that will be consumed soon
      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          token_uuid: meta.token.uuid,
          account_uuid: meta.account.uuid,
          wallet: meta.account_wallet,
          amount: nil,
          require_confirmation: true,

          # The consumption will expire after 1 second.
          consumption_lifetime: 1
        )

      request_topic = "transaction_request:#{transaction_request.id}"

      # Start listening to the channels for the transaction request created above
      Endpoint.subscribe(request_topic)

      # Making the consumption, since we made the request require_confirmation, it will
      # create a pending consumption that will need to be confirmed
      response =
        admin_user_request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: 100_000 * meta.token.subunit_to_unit,
          metadata: nil,
          token_id: nil,
          address: meta.alice_wallet.address
        })

      consumption_id = response["data"]["id"]
      assert response["success"] == true
      assert response["data"]["status"] == "pending"

      # The consumption is still valid...
      :timer.sleep(1000)
      # And now it's not!
      # We should receive a transaction_consumption_finalized event.

      # Let's also listen to the consumption channel.
      Endpoint.subscribe(response["data"]["socket_topic"])

      # We trigger the CRON task
      TransactionConsumptionScheduler.expire_all()

      # And we should now receive a finalized failed consumption.
      assert_receive %Phoenix.Socket.Broadcast{
        event: "transaction_consumption_finalized",
        topic: "transaction_request:" <> _,
        payload: payload
      }

      # Ensure the websocket serializer can serialize the payload
      {:socket_push, :text, encoded} =
        WebsocketResponseSerializer.fastlane!(%Broadcast{
          topic: "transaction_request:#{transaction_request.id}",
          event: "transaction_consumption_finalized",
          payload: payload
        })

      decoded = Poison.decode!(encoded)
      assert decoded["success"] == false
      assert decoded["error"]["code"] == "transaction_consumption:expired"

      assert_receive %Phoenix.Socket.Broadcast{
        event: "transaction_consumption_finalized",
        topic: "transaction_consumption:" <> _,
        payload: payload
      }

      # Ensure the websocket serializer can serialize the payload
      {:socket_push, :text, encoded} =
        WebsocketResponseSerializer.fastlane!(%Broadcast{
          topic: "transaction_consumption:#{consumption_id}",
          event: "transaction_consumption_finalized",
          payload: payload
        })

      decoded = Poison.decode!(encoded)
      assert decoded["success"] == false
      assert decoded["error"]["code"] == "transaction_consumption:expired"

      # If we try to approve it now, it will fail since it has already expired.
      response =
        admin_user_request("/transaction_consumption.approve", %{
          id: consumption_id
        })

      assert response["success"] == false
      assert response["data"]["code"] == "transaction_consumption:expired"

      # Unsubscribe from all channels
      Endpoint.unsubscribe("transaction_request:#{transaction_request.id}")
      Endpoint.unsubscribe("transaction_consumption:#{consumption_id}")
    end

    test "sends an error when approved without enough funds", meta do
      {:ok, _} = AccountUser.link(meta.account.uuid, meta.bob.uuid)

      # Create a require_confirmation transaction request that will be consumed soon
      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          token_uuid: meta.token.uuid,
          account_uuid: meta.account.uuid,
          user_uuid: meta.bob.uuid,
          wallet: meta.bob_wallet,
          amount: nil,
          require_confirmation: true
        )

      request_topic = "transaction_request:#{transaction_request.id}"

      # Start listening to the channels for the transaction request created above
      Endpoint.subscribe(request_topic)

      # Making the consumption, since we made the request require_confirmation, it will
      # create a pending consumption that will need to be confirmed
      response =
        admin_user_request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: 100_000 * meta.token.subunit_to_unit,
          metadata: nil,
          token_id: nil,
          address: meta.alice_wallet.address
        })

      consumption_id = response["data"]["id"]
      assert response["success"] == true
      assert response["data"]["status"] == "pending"
      assert response["data"]["transaction_id"] == nil

      # We check that we receive the confirmation request above in the
      # transaction request channel
      assert_receive %Phoenix.Socket.Broadcast{
        event: "transaction_consumption_request",
        topic: "transaction_request:" <> _,
        payload: payload
      }

      # Ensure the websocket serializer can serialize the payload
      {:socket_push, :text, encoded} =
        WebsocketResponseSerializer.fastlane!(%Broadcast{
          topic: "transaction_request:#{transaction_request.id}",
          event: "transaction_consumption_request",
          payload: payload
        })

      decoded = Poison.decode!(encoded)
      assert decoded["success"] == true

      # We need to know once the consumption has been approved, so let's
      # listen to the channel for it
      Endpoint.subscribe("transaction_consumption:#{consumption_id}")

      # Confirm the consumption
      response =
        admin_user_request("/transaction_consumption.approve", %{
          id: consumption_id
        })

      assert response["success"] == false
      assert response["data"]["code"] == "transaction:insufficient_funds"

      assert_receive %Phoenix.Socket.Broadcast{
        event: "transaction_consumption_finalized",
        topic: "transaction_consumption:" <> _,
        payload: payload
      }

      {:socket_push, :text, encoded} =
        WebsocketResponseSerializer.fastlane!(%Broadcast{
          topic: "transaction_consumption:#{consumption_id}",
          event: "transaction_consumption_finalized",
          payload: payload
        })

      decoded = Poison.decode!(encoded)
      assert decoded["success"] == false
      assert decoded["error"]["code"] == "transaction:insufficient_funds"
      assert "The specified wallet" <> _ = decoded["error"]["description"]

      # Unsubscribe from all channels
      Endpoint.unsubscribe("transaction_request:#{transaction_request.id}")
      Endpoint.unsubscribe("transaction_consumption:#{consumption_id}")
    end

    test "sends socket confirmation when require_confirmation and rejected", meta do
      mint!(meta.token)

      # Create a require_confirmation transaction request that will be consumed soon
      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          token_uuid: meta.token.uuid,
          account_uuid: meta.account.uuid,
          wallet: meta.account_wallet,
          amount: nil,
          require_confirmation: true,
          max_consumptions: 1
        )

      request_topic = "transaction_request:#{transaction_request.id}"

      # Start listening to the channels for the transaction request created above
      Endpoint.subscribe(request_topic)

      # Making the consumption, since we made the request require_confirmation, it will
      # create a pending consumption that will need to be confirmed
      response =
        admin_user_request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: 100_000 * meta.token.subunit_to_unit,
          metadata: nil,
          token_id: nil,
          provider_user_id: meta.bob.provider_user_id
        })

      consumption_id = response["data"]["id"]
      assert response["success"] == true
      assert response["data"]["status"] == "pending"
      assert response["data"]["transaction_id"] == nil

      # Retrieve what just got inserted
      inserted_consumption = TransactionConsumption.get(response["data"]["id"])

      # We check that we receive the confirmation request above in the
      # transaction request channel
      assert_receive %Phoenix.Socket.Broadcast{
        event: "transaction_consumption_request",
        topic: "transaction_request:" <> _,
        payload:
          %{
            # Ignore content
          }
      }

      # We need to know once the consumption has been approved, so let's
      # listen to the channel for it
      Endpoint.subscribe("transaction_consumption:#{consumption_id}")

      # Confirm the consumption
      response =
        admin_user_request("/transaction_consumption.reject", %{
          id: consumption_id
        })

      assert response["success"] == true
      assert response["data"]["id"] == inserted_consumption.id
      assert response["data"]["status"] == "rejected"
      assert response["data"]["rejected_at"] != nil
      assert response["data"]["approved_at"] == nil
      assert response["data"]["confirmed_at"] == nil

      # Check that a transaction was not inserted
      assert response["data"]["transaction_id"] == nil

      assert_receive %Phoenix.Socket.Broadcast{
        event: "transaction_consumption_finalized",
        topic: "transaction_consumption:" <> _,
        payload:
          %{
            # Ignore content
          }
      }

      # Check that we can consume for real now
      #
      # Making the consumption, since we made the request require_confirmation, it will
      # create a pending consumption that will need to be confirmed
      response =
        admin_user_request("/transaction_request.consume", %{
          idempotency_token: "1234",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: 100_000 * meta.token.subunit_to_unit,
          metadata: nil,
          token_id: nil,
          provider_user_id: meta.bob.provider_user_id
        })

      consumption_id = response["data"]["id"]
      assert response["success"] == true
      assert response["data"]["status"] == "pending"
      assert response["data"]["transaction_id"] == nil

      # Retrieve what just got inserted
      inserted_consumption = TransactionConsumption.get(response["data"]["id"])

      # We check that we receive the confirmation request above in the
      # transaction request channel
      assert_receive %Phoenix.Socket.Broadcast{
        event: "transaction_consumption_request",
        topic: "transaction_request:" <> _,
        payload:
          %{
            # Ignore content
          }
      }

      # We need to know once the consumption has been approved, so let's
      # listen to the channel for it
      Endpoint.subscribe("transaction_consumption:#{consumption_id}")

      # Confirm the consumption
      response =
        admin_user_request("/transaction_consumption.approve", %{
          id: consumption_id
        })

      assert response["success"] == true
      assert response["data"]["id"] == inserted_consumption.id
      assert response["data"]["status"] == "confirmed"
      assert response["data"]["confirmed_at"] != nil
      assert response["data"]["approved_at"] != nil
      assert response["data"]["rejected_at"] == nil

      # Check that a transaction was not inserted
      assert response["data"]["transaction_id"] != nil

      assert_receive %Phoenix.Socket.Broadcast{
        event: "transaction_consumption_finalized",
        topic: "transaction_consumption:" <> _,
        payload:
          %{
            # Ignore content
          }
      }

      # Unsubscribe from all channels
      Endpoint.unsubscribe("transaction_request:#{transaction_request.id}")
      Endpoint.unsubscribe("transaction_consumption:#{consumption_id}")
    end
  end
end
