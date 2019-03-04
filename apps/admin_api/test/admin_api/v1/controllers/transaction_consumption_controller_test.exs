# Copyright 2018-2019 OmiseGO Pte Ltd
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

defmodule AdminAPI.V1.TransactionConsumptionControllerTest do
  use AdminAPI.ConnCase, async: true

  alias EWalletDB.{
    Account,
    AccountUser,
    Repo,
    Token,
    Transaction,
    TransactionConsumption,
    User,
    Wallet
  }

  alias EWallet.{BalanceFetcher, TestEndpoint}
  alias EWallet.Web.{Orchestrator, V1.WebsocketResponseSerializer}
  alias Phoenix.Socket.Broadcast
  alias Utils.Helpers.DateFormatter

  alias EWallet.Web.V1.{
    AccountSerializer,
    TokenSerializer,
    TransactionRequestSerializer,
    TransactionSerializer,
    TransactionConsumptionOverlay
  }

  alias AdminAPI.V1.Endpoint
  alias EWallet.TransactionConsumptionScheduler

  alias ActivityLogger.System

  setup do
    {:ok, _} = TestEndpoint.start_link()

    account = Account.get_master_account()
    {:ok, alice} = :user |> params_for() |> User.insert()
    bob = get_test_user()
    {:ok, _} = AccountUser.link(account.uuid, bob.uuid, %System{})

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

    test_with_auths "returns all the transaction_consumptions", context do
      response =
        request("/transaction_consumption.all", %{
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      transfers = [
        context.tc_1,
        context.tc_2,
        context.tc_3
      ]

      assert length(response["data"]["data"]) == length(transfers)

      # All transfers made during setup should exist in the response
      assert Enum.all?(transfers, fn transfer ->
               Enum.any?(response["data"]["data"], fn data ->
                 transfer.id == data["id"]
               end)
             end)
    end

    test_with_auths "returns all the transaction_consumptions for a specific status", context do
      response =
        request("/transaction_consumption.all", %{
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
               context.tc_1.id,
               context.tc_2.id
             ]
    end

    test_with_auths "returns all transaction_consumptions filtered", context do
      response =
        request("/transaction_consumption.all", %{
          "sort_by" => "created_at",
          "sort_dir" => "asc",
          "search_term" => "pending"
        })

      assert response["data"]["data"] |> length() == 2

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               context.tc_1.id,
               context.tc_2.id
             ]
    end

    test_with_auths "returns all transaction_consumptions sorted and paginated", context do
      response =
        request("/transaction_consumption.all", %{
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
               context.tc_1.id,
               context.tc_2.id
             ]
    end

    # The endpoint will scope the result to the consumptions associated with the requester,
    # hence the customized factory attrs to make sure the results will be found.
    test_supports_match_any(
      "/transaction_consumption.all",
      :transaction_consumption,
      :correlation_id,
      factory_attrs: %{
        user_uuid: get_test_admin().uuid,
        account_uuid: Account.get_master_account().uuid
      }
    )

    # The endpoint will scope the result to the consumptions associated with the requester,
    # hence the customized factory attrs to make sure the results will be found.
    test_supports_match_all(
      "/transaction_consumption.all",
      :transaction_consumption,
      :correlation_id,
      factory_attrs: %{
        user_uuid: get_test_admin().uuid,
        account_uuid: Account.get_master_account().uuid
      }
    )
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

    test_with_auths "returns :invalid_parameter when account id is not provided" do
      response =
        request("/account.get_transaction_consumptions", %{
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      assert response == %{
               "data" => %{
                 "code" => "client:invalid_parameter",
                 "description" => "Invalid parameter provided. `id` is required.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }
    end

    test_with_auths "returns :account_id_not_found when id is not provided" do
      response =
        request("/account.get_transaction_consumptions", %{
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
                 "description" => "You are not allowed to perform the requested operation."
               }
             }
    end

    test_with_auths "returns all the transaction_consumptions for an account", context do
      response =
        request("/account.get_transaction_consumptions", %{
          "id" => context.account.id,
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      transfers = [
        context.tc_1,
        context.tc_2,
        context.tc_3
      ]

      assert length(response["data"]["data"]) == 3

      # All transfers made during setup should exist in the response
      assert Enum.all?(transfers, fn transfer ->
               Enum.any?(response["data"]["data"], fn data ->
                 transfer.id == data["id"]
               end)
             end)
    end

    test_with_auths "returns all the transaction_consumptions for a specific status", context do
      response =
        request("/account.get_transaction_consumptions", %{
          "id" => context.account.id,
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
               context.tc_1.id,
               context.tc_2.id
             ]
    end

    test_with_auths "returns all transaction_consumptions sorted and paginated", context do
      response =
        request("/account.get_transaction_consumptions", %{
          "id" => context.account.id,
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
               context.tc_1.id,
               context.tc_2.id
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

    test_with_auths "returns :invalid_parameter when id or provider_user_id is not provided" do
      response =
        request("/user.get_transaction_consumptions", %{
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      assert response == %{
               "data" => %{
                 "code" => "client:invalid_parameter",
                 "description" =>
                   "Invalid parameter provided. `user_id` or `provider_user_id` is required.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }
    end

    test_with_auths "returns :id_not_found when id is not valid" do
      response =
        request("/user.get_transaction_consumptions", %{
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
                 "description" => "There is no user corresponding to the provided id."
               }
             }
    end

    test_with_auths "returns :provider_user_id_not_found when provider_user_id is not valid" do
      response =
        request("/user.get_transaction_consumptions", %{
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
                   "There is no user corresponding to the provided provider_user_id."
               }
             }
    end

    test_with_auths "returns all the transaction_consumptions for a user when given an id",
                    context do
      response =
        request("/user.get_transaction_consumptions", %{
          "id" => context.user.id,
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      assert length(response["data"]["data"]) == 2

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               context.tc_2.id,
               context.tc_3.id
             ]
    end

    test_with_auths "returns all the transaction_consumptions for a user when given a user_id",
                    context do
      response =
        request("/user.get_transaction_consumptions", %{
          "user_id" => context.user.id,
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      assert length(response["data"]["data"]) == 2

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               context.tc_2.id,
               context.tc_3.id
             ]
    end

    test_with_auths "returns all the transaction_consumptions for a user when given a provider_user_id",
                    context do
      response =
        request("/user.get_transaction_consumptions", %{
          "provider_user_id" => context.user.provider_user_id,
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      assert length(response["data"]["data"]) == 2

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               context.tc_2.id,
               context.tc_3.id
             ]
    end

    test_with_auths "returns all the transaction_consumptions for a specific status", context do
      response =
        request("/user.get_transaction_consumptions", %{
          "user_id" => context.user.id,
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
               context.tc_2.id
             ]
    end

    test_with_auths "returns all transaction_consumptions sorted and paginated", context do
      response =
        request("/user.get_transaction_consumptions", %{
          "user_id" => context.user.id,
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
               context.tc_2.id,
               context.tc_3.id
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

    test_with_auths "returns :invalid_parameter when formatted_transaction_request_id is not provided" do
      response =
        request("/transaction_request.get_transaction_consumptions", %{
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      assert response == %{
               "data" => %{
                 "code" => "client:invalid_parameter",
                 "description" =>
                   "Invalid parameter provided. `formatted_transaction_request_id` is required.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }
    end

    test_with_auths "returns :unauthorized when formatted_transaction_request_id is not valid" do
      response =
        request("/transaction_request.get_transaction_consumptions", %{
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
                 "description" => "You are not allowed to perform the requested operation."
               }
             }
    end

    test_with_auths "returns all the transaction_consumptions for a transaction_request",
                    context do
      response =
        request("/transaction_request.get_transaction_consumptions", %{
          "formatted_transaction_request_id" => context.transaction_request.id,
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      assert length(response["data"]["data"]) == 2

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               context.tc_2.id,
               context.tc_3.id
             ]
    end

    test_with_auths "returns all the transaction_consumptions for a specific status", context do
      response =
        request("/transaction_request.get_transaction_consumptions", %{
          "formatted_transaction_request_id" => context.transaction_request.id,
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
               context.tc_2.id
             ]
    end

    test_with_auths "returns all transaction_consumptions sorted and paginated", context do
      response =
        request("/transaction_request.get_transaction_consumptions", %{
          "formatted_transaction_request_id" => context.transaction_request.id,
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
               context.tc_2.id,
               context.tc_3.id
             ]
    end
  end

  describe "/wallet.get_transaction_consumptions" do
    setup do
      account = insert(:account)
      wallet = insert(:wallet)
      {:ok, _} = AccountUser.link(account.uuid, wallet.user_uuid, %System{})

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

    test_with_auths "returns :invalid_parameter when address is not provided" do
      response =
        request("/wallet.get_transaction_consumptions", %{
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      assert response == %{
               "data" => %{
                 "code" => "client:invalid_parameter",
                 "description" => "Invalid parameter provided. `address` is required.",
                 "messages" => nil,
                 "object" => "error"
               },
               "success" => false,
               "version" => "1"
             }
    end

    test_with_auths "returns :unauthorized when address is not provided" do
      response =
        request("/wallet.get_transaction_consumptions", %{
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
                 "description" => "You are not allowed to perform the requested operation."
               }
             }
    end

    test_with_auths "returns all the transaction_consumptions for a wallet", context do
      response =
        request("/wallet.get_transaction_consumptions", %{
          "address" => context.wallet.address,
          "sort_by" => "created",
          "sort_dir" => "asc"
        })

      assert length(response["data"]["data"]) == 2

      assert Enum.map(response["data"]["data"], fn t ->
               t["id"]
             end) == [
               context.tc_2.id,
               context.tc_3.id
             ]
    end

    test_with_auths "returns all the transaction_consumptions for a specific status", context do
      response =
        request("/wallet.get_transaction_consumptions", %{
          "address" => context.wallet.address,
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
               context.tc_2.id
             ]
    end

    test_with_auths "returns all transaction_consumptions sorted and paginated", context do
      response =
        request("/wallet.get_transaction_consumptions", %{
          "address" => context.wallet.address,
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
               context.tc_2.id,
               context.tc_3.id
             ]
    end
  end

  describe "/transaction_consumption.get" do
    test_with_auths "returns the transaction consumption" do
      transaction_consumption = insert(:transaction_consumption)

      response =
        request("/transaction_consumption.get", %{
          id: transaction_consumption.id
        })

      assert response["success"] == true
      assert response["data"]["id"] == transaction_consumption.id
    end

    test_with_auths "returns an error when the consumption ID is not found" do
      response =
        request("/transaction_consumption.get", %{
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
    test_with_auths "consumes the request and transfers the appropriate amount of tokens",
                    context do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: context.token.uuid,
          user_uuid: context.alice.uuid,
          wallet: context.alice_wallet,
          amount: 100_000 * context.token.subunit_to_unit
        )

      set_initial_balance(%{
        address: context.bob_wallet.address,
        token: context.token,
        amount: 150_000
      })

      response =
        request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil,
          account_id: context.account.id
        })

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)

      {:ok, inserted_consumption} =
        Orchestrator.one(inserted_consumption, TransactionConsumptionOverlay)

      request = inserted_consumption.transaction_request
      inserted_transaction = inserted_consumption.transaction

      assert response == %{
               "success" => true,
               "version" => "1",
               "data" => %{
                 "address" => context.account_wallet.address,
                 "amount" => nil,
                 "estimated_consumption_amount" => 100_000 * context.token.subunit_to_unit,
                 "estimated_request_amount" => 100_000 * context.token.subunit_to_unit,
                 "finalized_request_amount" => 100_000 * context.token.subunit_to_unit,
                 "finalized_consumption_amount" => 100_000 * context.token.subunit_to_unit,
                 "correlation_id" => nil,
                 "id" => inserted_consumption.id,
                 "socket_topic" => "transaction_consumption:#{inserted_consumption.id}",
                 "idempotency_token" => "123",
                 "object" => "transaction_consumption",
                 "status" => "confirmed",
                 "token_id" => context.token.id,
                 "token" => context.token |> TokenSerializer.serialize() |> stringify_keys(),
                 "transaction_request_id" => transaction_request.id,
                 "transaction_request" =>
                   request |> TransactionRequestSerializer.serialize() |> stringify_keys(),
                 "transaction_id" => inserted_transaction.id,
                 "transaction" =>
                   inserted_transaction |> TransactionSerializer.serialize() |> stringify_keys(),
                 "user_id" => nil,
                 "user" => nil,
                 "account_id" => context.account.id,
                 "account" =>
                   context.account |> AccountSerializer.serialize() |> stringify_keys(),
                 "exchange_account" => nil,
                 "exchange_account_id" => nil,
                 "exchange_wallet" => nil,
                 "exchange_wallet_address" => nil,
                 "metadata" => %{},
                 "encrypted_metadata" => %{},
                 "expiration_date" => nil,
                 "created_at" => DateFormatter.to_iso8601(inserted_consumption.inserted_at),
                 "approved_at" => DateFormatter.to_iso8601(inserted_consumption.approved_at),
                 "rejected_at" => DateFormatter.to_iso8601(inserted_consumption.rejected_at),
                 "confirmed_at" => DateFormatter.to_iso8601(inserted_consumption.confirmed_at),
                 "failed_at" => DateFormatter.to_iso8601(inserted_consumption.failed_at),
                 "expired_at" => nil
               }
             }

      assert inserted_transaction.from_amount == 100_000 * context.token.subunit_to_unit
      assert inserted_transaction.from_token_uuid == context.token.uuid
      assert inserted_transaction.to_amount == 100_000 * context.token.subunit_to_unit
      assert inserted_transaction.to_token_uuid == context.token.uuid
      assert inserted_transaction.to == context.alice_wallet.address
      assert inserted_transaction.from == context.account_wallet.address
      assert inserted_transaction.local_ledger_uuid != nil
    end

    test_with_auths "fails to consume when trying to send from a burn wallet", context do
      burn_wallet = Account.get_default_burn_wallet(context.account)

      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          token_uuid: context.token.uuid,
          wallet: burn_wallet,
          amount: 100_000 * context.token.subunit_to_unit
        )

      response =
        request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil,
          user_id: context.bob.id
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `from` can't be the address of a burn wallet."

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      assert inserted_consumption.error_code == "client:invalid_parameter"

      assert inserted_consumption.error_description ==
               "Invalid parameter provided. `from` can't be the address of a burn wallet."
    end

    test_with_auths "consumes the request and transfers the appropriate amount of tokens with string",
                    context do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: context.token.uuid,
          user_uuid: context.alice.uuid,
          wallet: context.alice_wallet,
          amount: nil
        )

      set_initial_balance(%{
        address: context.bob_wallet.address,
        token: context.token,
        amount: 100_000 * context.token.subunit_to_unit
      })

      response =
        request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: "10000000",
          address: nil,
          metadata: nil,
          token_id: nil,
          account_id: context.account.id
        })

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)

      {:ok, inserted_consumption} =
        Orchestrator.one(inserted_consumption, TransactionConsumptionOverlay)

      request = inserted_consumption.transaction_request
      inserted_transaction = inserted_consumption.transaction

      assert response == %{
               "success" => true,
               "version" => "1",
               "data" => %{
                 "address" => context.account_wallet.address,
                 "amount" => 100_000 * context.token.subunit_to_unit,
                 "estimated_consumption_amount" => 100_000 * context.token.subunit_to_unit,
                 "estimated_request_amount" => 100_000 * context.token.subunit_to_unit,
                 "finalized_request_amount" => 100_000 * context.token.subunit_to_unit,
                 "finalized_consumption_amount" => 100_000 * context.token.subunit_to_unit,
                 "correlation_id" => nil,
                 "id" => inserted_consumption.id,
                 "socket_topic" => "transaction_consumption:#{inserted_consumption.id}",
                 "idempotency_token" => "123",
                 "object" => "transaction_consumption",
                 "status" => "confirmed",
                 "token_id" => context.token.id,
                 "token" => context.token |> TokenSerializer.serialize() |> stringify_keys(),
                 "transaction_request_id" => transaction_request.id,
                 "transaction_request" =>
                   request |> TransactionRequestSerializer.serialize() |> stringify_keys(),
                 "transaction_id" => inserted_transaction.id,
                 "transaction" =>
                   inserted_transaction |> TransactionSerializer.serialize() |> stringify_keys(),
                 "user_id" => nil,
                 "user" => nil,
                 "account_id" => context.account.id,
                 "account" =>
                   context.account |> AccountSerializer.serialize() |> stringify_keys(),
                 "exchange_account" => nil,
                 "exchange_account_id" => nil,
                 "exchange_wallet" => nil,
                 "exchange_wallet_address" => nil,
                 "metadata" => %{},
                 "encrypted_metadata" => %{},
                 "expiration_date" => nil,
                 "created_at" => DateFormatter.to_iso8601(inserted_consumption.inserted_at),
                 "approved_at" => DateFormatter.to_iso8601(inserted_consumption.approved_at),
                 "rejected_at" => DateFormatter.to_iso8601(inserted_consumption.rejected_at),
                 "confirmed_at" => DateFormatter.to_iso8601(inserted_consumption.confirmed_at),
                 "failed_at" => DateFormatter.to_iso8601(inserted_consumption.failed_at),
                 "expired_at" => nil
               }
             }

      assert inserted_transaction.from_amount == 100_000 * context.token.subunit_to_unit
      assert inserted_transaction.from_token_uuid == context.token.uuid
      assert inserted_transaction.to_amount == 100_000 * context.token.subunit_to_unit
      assert inserted_transaction.to_token_uuid == context.token.uuid
      assert inserted_transaction.to == context.alice_wallet.address
      assert inserted_transaction.from == context.account_wallet.address
      assert inserted_transaction.local_ledger_uuid != nil
    end

    test_with_auths "consumes the request and transfers with exchange details in request",
                    context do
      token_2 = insert(:token)
      mint!(token_2)
      _pair = insert(:exchange_pair, from_token: context.token, to_token: token_2, rate: 2)

      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          token_uuid: context.token.uuid,
          user_uuid: context.alice.uuid,
          wallet: context.alice_wallet,
          amount: 100_000 * context.token.subunit_to_unit,
          exchange_account_uuid: context.account.uuid,
          exchange_wallet_address: context.account_wallet.address
        )

      set_initial_balance(%{
        address: context.alice_wallet.address,
        token: context.token,
        amount: 150_000
      })

      response =
        request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: token_2.id,
          user_id: context.bob.id
        })

      assert response["success"] == true

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transaction = Repo.get(Transaction, inserted_consumption.transaction_uuid)

      assert response["data"]["amount"] == nil

      assert response["data"]["finalized_request_amount"] ==
               100_000 * context.token.subunit_to_unit

      assert response["data"]["finalized_consumption_amount"] == 200_000 * token_2.subunit_to_unit

      assert response["data"]["estimated_request_amount"] ==
               100_000 * context.token.subunit_to_unit

      assert response["data"]["estimated_consumption_amount"] == 200_000 * token_2.subunit_to_unit
      assert response["data"]["token_id"] == token_2.id
      assert response["data"]["address"] == context.bob_wallet.address
      assert response["data"]["user_id"] == context.bob.id

      assert response["data"]["transaction_request"]["amount"] ==
               100_000 * context.token.subunit_to_unit

      assert response["data"]["transaction_request"]["token_id"] == context.token.id
      assert response["data"]["transaction_request"]["address"] == context.alice_wallet.address
      assert response["data"]["transaction_request"]["user_id"] == context.alice.id

      assert response["data"]["transaction"] != nil
      assert response["data"]["transaction"]["exchange"]["exchange_pair"]["to_token_id"] != nil
      assert response["data"]["transaction"]["exchange"]["exchange_pair"]["from_token_id"] != nil

      assert inserted_transaction.from_amount == 100_000 * context.token.subunit_to_unit
      assert inserted_transaction.from_token_uuid == context.token.uuid
      assert inserted_transaction.to_amount == 200_000 * token_2.subunit_to_unit
      assert inserted_transaction.to_token_uuid == token_2.uuid
      assert inserted_transaction.to == context.bob_wallet.address
      assert inserted_transaction.from == context.alice_wallet.address
      assert inserted_transaction.local_ledger_uuid != nil

      {:ok, b1} = BalanceFetcher.get(context.token.id, context.alice_wallet)
      {:ok, b2} = BalanceFetcher.get(token_2.id, context.alice_wallet)
      assert Enum.at(b1.balances, 0).amount == (150_000 - 100_000) * context.token.subunit_to_unit
      assert Enum.at(b2.balances, 0).amount == 0

      {:ok, b1} = BalanceFetcher.get(context.token.id, context.bob_wallet)
      {:ok, b2} = BalanceFetcher.get(token_2.id, context.bob_wallet)
      assert Enum.at(b1.balances, 0).amount == 0
      assert Enum.at(b2.balances, 0).amount == 100_000 * 2 * context.token.subunit_to_unit
    end

    test_with_auths "consumes the request and exchange with exchange_wallet in consumption",
                    context do
      token_2 = insert(:token)
      mint!(token_2)
      _pair = insert(:exchange_pair, from_token: context.token, to_token: token_2, rate: 2)

      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          token_uuid: context.token.uuid,
          user_uuid: context.alice.uuid,
          wallet: context.alice_wallet,
          amount: 100_000 * context.token.subunit_to_unit
        )

      set_initial_balance(%{
        address: context.alice_wallet.address,
        token: context.token,
        amount: 150_000
      })

      response =
        request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: token_2.id,
          user_id: context.bob.id,
          exchange_wallet_address: context.account_wallet.address
        })

      assert response["success"] == true

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transaction = Repo.get(Transaction, inserted_consumption.transaction_uuid)

      assert response["data"]["amount"] == nil

      assert response["data"]["finalized_request_amount"] ==
               100_000 * context.token.subunit_to_unit

      assert response["data"]["finalized_consumption_amount"] == 200_000 * token_2.subunit_to_unit

      assert response["data"]["estimated_request_amount"] ==
               100_000 * context.token.subunit_to_unit

      assert response["data"]["estimated_consumption_amount"] == 200_000 * token_2.subunit_to_unit
      assert response["data"]["token_id"] == token_2.id
      assert response["data"]["exchange_wallet_address"] == context.account_wallet.address
      assert response["data"]["exchange_account_id"] == context.account.id

      assert response["data"]["transaction_request"]["amount"] ==
               100_000 * context.token.subunit_to_unit

      assert response["data"]["transaction_request"]["token_id"] == context.token.id
      assert response["data"]["transaction_request"]["address"] == context.alice_wallet.address
      assert response["data"]["transaction_request"]["user_id"] == context.alice.id
      assert response["data"]["transaction_request"]["exchange_wallet_address"] == nil
      assert response["data"]["transaction_request"]["exchange_accout_id"] == nil

      assert inserted_transaction.from_amount == 100_000 * context.token.subunit_to_unit
      assert inserted_transaction.from_token_uuid == context.token.uuid
      assert inserted_transaction.to_amount == 200_000 * token_2.subunit_to_unit
      assert inserted_transaction.to_token_uuid == token_2.uuid
      assert inserted_transaction.to == context.bob_wallet.address
      assert inserted_transaction.from == context.alice_wallet.address
      assert inserted_transaction.local_ledger_uuid != nil

      {:ok, b1} = BalanceFetcher.get(context.token.id, context.alice_wallet)
      {:ok, b2} = BalanceFetcher.get(token_2.id, context.alice_wallet)
      assert Enum.at(b1.balances, 0).amount == (150_000 - 100_000) * context.token.subunit_to_unit
      assert Enum.at(b2.balances, 0).amount == 0

      {:ok, b1} = BalanceFetcher.get(context.token.id, context.bob_wallet)
      {:ok, b2} = BalanceFetcher.get(token_2.id, context.bob_wallet)
      assert Enum.at(b1.balances, 0).amount == 0
      assert Enum.at(b2.balances, 0).amount == 100_000 * 2 * context.token.subunit_to_unit
    end

    test_with_auths "consumes the request and exchange with exchange_account in consumption",
                    context do
      token_2 = insert(:token)
      mint!(token_2)
      _pair = insert(:exchange_pair, from_token: context.token, to_token: token_2, rate: 2)

      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          token_uuid: context.token.uuid,
          user_uuid: context.alice.uuid,
          wallet: context.alice_wallet,
          amount: 100_000 * context.token.subunit_to_unit
        )

      set_initial_balance(%{
        address: context.alice_wallet.address,
        token: context.token,
        amount: 150_000
      })

      response =
        request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: token_2.id,
          user_id: context.bob.id,
          exchange_account_id: context.account.id
        })

      assert response["success"] == true

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transaction = Repo.get(Transaction, inserted_consumption.transaction_uuid)

      assert response["data"]["amount"] == nil

      assert response["data"]["finalized_request_amount"] ==
               100_000 * context.token.subunit_to_unit

      assert response["data"]["finalized_consumption_amount"] == 200_000 * token_2.subunit_to_unit

      assert response["data"]["estimated_request_amount"] ==
               100_000 * context.token.subunit_to_unit

      assert response["data"]["estimated_consumption_amount"] == 200_000 * token_2.subunit_to_unit
      assert response["data"]["token_id"] == token_2.id
      assert response["data"]["exchange_wallet_address"] == context.account_wallet.address
      assert response["data"]["exchange_account_id"] == context.account.id

      assert response["data"]["transaction_request"]["amount"] ==
               100_000 * context.token.subunit_to_unit

      assert response["data"]["transaction_request"]["token_id"] == context.token.id
      assert response["data"]["transaction_request"]["address"] == context.alice_wallet.address
      assert response["data"]["transaction_request"]["user_id"] == context.alice.id
      assert response["data"]["transaction_request"]["exchange_wallet_address"] == nil
      assert response["data"]["transaction_request"]["exchange_accout_id"] == nil

      assert inserted_transaction.from_amount == 100_000 * context.token.subunit_to_unit
      assert inserted_transaction.from_token_uuid == context.token.uuid
      assert inserted_transaction.to_amount == 200_000 * token_2.subunit_to_unit
      assert inserted_transaction.to_token_uuid == token_2.uuid
      assert inserted_transaction.to == context.bob_wallet.address
      assert inserted_transaction.from == context.alice_wallet.address
      assert inserted_transaction.local_ledger_uuid != nil

      {:ok, b1} = BalanceFetcher.get(context.token.id, context.alice_wallet)
      {:ok, b2} = BalanceFetcher.get(token_2.id, context.alice_wallet)
      assert Enum.at(b1.balances, 0).amount == (150_000 - 100_000) * context.token.subunit_to_unit
      assert Enum.at(b2.balances, 0).amount == 0

      {:ok, b1} = BalanceFetcher.get(context.token.id, context.bob_wallet)
      {:ok, b2} = BalanceFetcher.get(token_2.id, context.bob_wallet)
      assert Enum.at(b1.balances, 0).amount == 0
      assert Enum.at(b2.balances, 0).amount == 100_000 * 2 * context.token.subunit_to_unit
    end

    test_with_auths "transfer and exchange if request and consumption specify the same exchange wallet address",
                    context do
      token_2 = insert(:token)
      mint!(token_2)
      _pair = insert(:exchange_pair, from_token: context.token, to_token: token_2, rate: 2)

      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          token_uuid: context.token.uuid,
          user_uuid: context.alice.uuid,
          wallet: context.alice_wallet,
          amount: 100_000 * context.token.subunit_to_unit,
          exchange_account_uuid: context.account.uuid,
          exchange_wallet_address: context.account_wallet.address
        )

      set_initial_balance(%{
        address: context.alice_wallet.address,
        token: context.token,
        amount: 150_000
      })

      response =
        request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: token_2.id,
          user_id: context.bob.id,
          exchange_account_id: context.account.id
        })

      assert response["success"] == true

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transaction = Repo.get(Transaction, inserted_consumption.transaction_uuid)

      assert response["data"]["amount"] == nil

      assert response["data"]["finalized_request_amount"] ==
               100_000 * context.token.subunit_to_unit

      assert response["data"]["finalized_consumption_amount"] == 200_000 * token_2.subunit_to_unit

      assert response["data"]["estimated_request_amount"] ==
               100_000 * context.token.subunit_to_unit

      assert response["data"]["estimated_consumption_amount"] == 200_000 * token_2.subunit_to_unit
      assert response["data"]["token_id"] == token_2.id
      assert response["data"]["exchange_wallet_address"] == context.account_wallet.address
      assert response["data"]["exchange_account_id"] == context.account.id

      assert response["data"]["transaction_request"]["amount"] ==
               100_000 * context.token.subunit_to_unit

      assert response["data"]["transaction_request"]["token_id"] == context.token.id
      assert response["data"]["transaction_request"]["address"] == context.alice_wallet.address
      assert response["data"]["transaction_request"]["user_id"] == context.alice.id

      assert response["data"]["transaction_request"]["exchange_wallet_address"] ==
               context.account_wallet.address

      assert response["data"]["transaction_request"]["exchange_account_id"] == context.account.id

      assert inserted_transaction.from_amount == 100_000 * context.token.subunit_to_unit
      assert inserted_transaction.from_token_uuid == context.token.uuid
      assert inserted_transaction.to_amount == 200_000 * token_2.subunit_to_unit
      assert inserted_transaction.to_token_uuid == token_2.uuid
      assert inserted_transaction.to == context.bob_wallet.address
      assert inserted_transaction.from == context.alice_wallet.address
      assert inserted_transaction.local_ledger_uuid != nil

      {:ok, b1} = BalanceFetcher.get(context.token.id, context.alice_wallet)
      {:ok, b2} = BalanceFetcher.get(token_2.id, context.alice_wallet)
      assert Enum.at(b1.balances, 0).amount == (150_000 - 100_000) * context.token.subunit_to_unit
      assert Enum.at(b2.balances, 0).amount == 0

      {:ok, b1} = BalanceFetcher.get(context.token.id, context.bob_wallet)
      {:ok, b2} = BalanceFetcher.get(token_2.id, context.bob_wallet)
      assert Enum.at(b1.balances, 0).amount == 0
      assert Enum.at(b2.balances, 0).amount == 100_000 * 2 * context.token.subunit_to_unit
    end

    test_with_auths "fails to consume if exchange details are different and already specified in request",
                    context do
      {:ok, account_2} = :account |> params_for() |> Account.insert()
      token_2 = insert(:token)
      mint!(token_2)
      _pair = insert(:exchange_pair, from_token: context.token, to_token: token_2, rate: 2)

      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          token_uuid: context.token.uuid,
          user_uuid: context.alice.uuid,
          wallet: context.alice_wallet,
          amount: 100_000 * context.token.subunit_to_unit,
          exchange_account_uuid: context.account.uuid,
          exchange_wallet_address: context.account_wallet.address
        )

      set_initial_balance(%{
        address: context.alice_wallet.address,
        token: context.token,
        amount: 150_000
      })

      response =
        request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: token_2.id,
          user_id: context.bob.id,
          exchange_account_id: account_2.id
        })

      assert response["success"] == false
      assert response["data"]["code"] == "consumption:request_already_contains_exchange_wallet"

      assert response["data"]["description"] ==
               "The transaction request for the given consumption already specify an exchange account and/or wallet."
    end

    test_with_auths "fails to consume and return an error when amount is not specified",
                    context do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: context.token.uuid,
          user_uuid: context.alice.uuid,
          wallet: context.alice_wallet,
          amount: nil
        )

      response =
        request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil,
          account_id: context.account.id
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `amount` is required for transaction consumption."
    end

    test_with_auths "fails to consume and return an error when amount is a decimal number",
                    context do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: context.token.uuid,
          user_uuid: context.alice.uuid,
          wallet: context.alice_wallet,
          amount: nil
        )

      response =
        request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: 1.2365,
          address: nil,
          metadata: nil,
          token_id: nil,
          account_id: context.account.id
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `amount` is not an integer: 1.2365."
    end

    test_with_auths "fails to consume and return an insufficient funds error", context do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: context.token.uuid,
          user_uuid: context.alice.uuid,
          wallet: context.alice_wallet,
          amount: 100_000 * context.token.subunit_to_unit
        )

      response =
        request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil,
          account_id: context.account.id
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
                   "The specified wallet (#{context.account_wallet.address}) does not contain enough funds. Available: 0 #{
                     context.token.id
                   } - Attempted debit: 100000 #{context.token.id}"
               }
             }

      assert inserted_transaction.from_amount == 100_000 * context.token.subunit_to_unit
      assert inserted_transaction.from_token_uuid == context.token.uuid
      assert inserted_transaction.to_amount == 100_000 * context.token.subunit_to_unit
      assert inserted_transaction.to_token_uuid == context.token.uuid
      assert inserted_transaction.to == context.alice_wallet.address
      assert inserted_transaction.from == context.account_wallet.address
      assert inserted_transaction.error_code == "insufficient_funds"
      assert inserted_transaction.error_description == nil

      assert inserted_transaction.error_data == %{
               "address" => context.account_wallet.address,
               "amount_to_debit" => 100_000 * context.token.subunit_to_unit,
               "current_amount" => 0,
               "token_id" => context.token.id
             }
    end

    test_with_auths "fails to consume when token is disabled", context do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: context.token.uuid,
          user_uuid: context.alice.uuid,
          wallet: context.alice_wallet,
          amount: 100_000 * context.token.subunit_to_unit
        )

      {:ok, token} =
        Token.enable_or_disable(context.token, %{enabled: false, originator: %System{}})

      response =
        request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: token.id,
          account_id: context.account.id
        })

      assert response["success"] == false
      assert response["data"]["code"] == "token:disabled"
    end

    test_with_auths "fails to consume when wallet is disabled", context do
      {:ok, wallet} =
        Wallet.insert_secondary_or_burn(%{
          "account_uuid" => context.account.uuid,
          "name" => "MySecondary",
          "identifier" => "secondary",
          "originator" => %System{}
        })

      {:ok, wallet} = Wallet.enable_or_disable(wallet, %{enabled: false, originator: %System{}})

      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: context.token.uuid,
          user_uuid: context.alice.uuid,
          wallet: context.alice_wallet,
          amount: 100_000 * context.token.subunit_to_unit
        )

      response =
        request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: wallet.address,
          metadata: nil,
          token_id: nil,
          account_id: context.account.id
        })

      assert response["success"] == false
      assert response["data"]["code"] == "wallet:disabled"
    end

    test_with_auths "returns with preload if `embed` attribute is given", context do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: context.token.uuid,
          user_uuid: context.alice.uuid,
          wallet: context.alice_wallet,
          amount: 100_000 * context.token.subunit_to_unit
        )

      set_initial_balance(%{
        address: context.bob_wallet.address,
        token: context.token,
        amount: 150_000
      })

      response =
        request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil,
          account_id: context.account.id,
          embed: ["account"]
        })

      assert response["data"]["account"] != nil
    end

    test_with_auths "returns same transaction request consumption when idempotency token is the same",
                    context do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: context.token.uuid,
          account_uuid: context.account.uuid,
          user_uuid: context.alice.uuid,
          wallet: context.alice_wallet,
          amount: 100_000 * context.token.subunit_to_unit
        )

      set_initial_balance(%{
        address: context.bob_wallet.address,
        token: context.token,
        amount: 150_000
      })

      response =
        request("/transaction_request.consume", %{
          idempotency_token: "1234",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil,
          account_id: context.account.id
        })

      inserted_consumption = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transaction = Repo.get(Transaction, inserted_consumption.transaction_uuid)

      assert response["success"] == true
      assert response["data"]["id"] == inserted_consumption.id

      response =
        request("/transaction_request.consume", %{
          idempotency_token: "1234",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil,
          account_id: context.account.id
        })

      inserted_consumption_2 = TransactionConsumption |> Repo.all() |> Enum.at(0)
      inserted_transaction_2 = Repo.get(Transaction, inserted_consumption.transaction_uuid)

      assert response["success"] == true
      assert response["data"]["id"] == inserted_consumption_2.id
      assert inserted_consumption.uuid == inserted_consumption_2.uuid
      assert inserted_transaction.uuid == inserted_transaction_2.uuid
    end

    test_with_auths "returns idempotency error if header is not specified" do
      response =
        request("/transaction_request.consume", %{
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
                 "description" => "Invalid parameter provided.",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test_with_auths "sends socket confirmation when require_confirmation and approved", context do
      mint!(context.token)

      # Create a require_confirmation transaction request that will be consumed soon
      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          token_uuid: context.token.uuid,
          account_uuid: context.account.uuid,
          wallet: context.account_wallet,
          amount: nil,
          require_confirmation: true
        )

      request_topic = "transaction_request:#{transaction_request.id}"

      # Start listening to the channels for the transaction request created above
      Endpoint.subscribe(request_topic)

      # Making the consumption, since we made the request require_confirmation, it will
      # create a pending consumption that will need to be confirmed
      response =
        request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: 100_000 * context.token.subunit_to_unit,
          metadata: nil,
          token_id: nil,
          provider_user_id: context.bob.provider_user_id
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
        request("/transaction_consumption.approve", %{
          id: consumption_id
        })

      assert response["success"] == true
      assert response["data"]["id"] == inserted_consumption.id
      assert response["data"]["status"] == "confirmed"
      assert response["data"]["approved_at"] != nil
      assert response["data"]["confirmed_at"] != nil

      # Check that a transaction was inserted
      inserted_transaction = Repo.get_by(Transaction, id: response["data"]["transaction_id"])
      assert inserted_transaction.from_amount == 100_000 * context.token.subunit_to_unit
      assert inserted_transaction.from_token_uuid == context.token.uuid
      assert inserted_transaction.to_amount == 100_000 * context.token.subunit_to_unit
      assert inserted_transaction.to_token_uuid == context.token.uuid
      assert inserted_transaction.to == context.bob_wallet.address
      assert inserted_transaction.from == context.account_wallet.address
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

    test_with_auths "sends socket confirmation when require_confirmation and approved between users",
                    context do
      # bob = test_user
      set_initial_balance(%{
        address: context.bob_wallet.address,
        token: context.token,
        amount: 1_000_000 * context.token.subunit_to_unit
      })

      # Create a require_confirmation transaction request that will be consumed soon
      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          token_uuid: context.token.uuid,
          account_uuid: context.account.uuid,
          user_uuid: context.bob.uuid,
          wallet: context.bob_wallet,
          amount: nil,
          require_confirmation: true
        )

      request_topic = "transaction_request:#{transaction_request.id}"

      # Start listening to the channels for the transaction request created above
      Endpoint.subscribe(request_topic)

      # Making the consumption, since we made the request require_confirmation, it will
      # create a pending consumption that will need to be confirmed
      response =
        request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: 100_000 * context.token.subunit_to_unit,
          metadata: nil,
          token_id: nil,
          address: context.alice_wallet.address
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
        request("/transaction_consumption.approve", %{
          id: consumption_id
        })

      assert response["success"] == true
      assert response["data"]["id"] == inserted_consumption.id
      assert response["data"]["status"] == "confirmed"
      assert response["data"]["approved_at"] != nil
      assert response["data"]["confirmed_at"] != nil

      # Check that a transaction was inserted
      inserted_transaction = Repo.get_by(Transaction, id: response["data"]["transaction_id"])
      assert inserted_transaction.from_amount == 100_000 * context.token.subunit_to_unit
      assert inserted_transaction.to_amount == 100_000 * context.token.subunit_to_unit
      assert inserted_transaction.from_token_uuid == context.token.uuid
      assert inserted_transaction.to_token_uuid == context.token.uuid
      assert inserted_transaction.to == context.alice_wallet.address
      assert inserted_transaction.from == context.bob_wallet.address
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

    test_with_auths "sends a websocket expiration event when a consumption expires", context do
      # bob = test_user
      set_initial_balance(%{
        address: context.bob_wallet.address,
        token: context.token,
        amount: 1_000_000 * context.token.subunit_to_unit
      })

      # Create a require_confirmation transaction request that will be consumed soon
      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          token_uuid: context.token.uuid,
          account_uuid: context.account.uuid,
          wallet: context.account_wallet,
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
        request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: 100_000 * context.token.subunit_to_unit,
          metadata: nil,
          token_id: nil,
          address: context.alice_wallet.address
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
        request("/transaction_consumption.approve", %{
          id: consumption_id
        })

      assert response["success"] == false
      assert response["data"]["code"] == "transaction_consumption:expired"

      # Unsubscribe from all channels
      Endpoint.unsubscribe("transaction_request:#{transaction_request.id}")
      Endpoint.unsubscribe("transaction_consumption:#{consumption_id}")
    end

    test_with_auths "sends an error when approved without enough funds", context do
      {:ok, _} = AccountUser.link(context.account.uuid, context.bob.uuid, %System{})

      # Create a require_confirmation transaction request that will be consumed soon
      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          token_uuid: context.token.uuid,
          account_uuid: context.account.uuid,
          user_uuid: context.bob.uuid,
          wallet: context.bob_wallet,
          amount: nil,
          require_confirmation: true
        )

      request_topic = "transaction_request:#{transaction_request.id}"

      # Start listening to the channels for the transaction request created above
      Endpoint.subscribe(request_topic)

      # Making the consumption, since we made the request require_confirmation, it will
      # create a pending consumption that will need to be confirmed
      response =
        request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: 100_000 * context.token.subunit_to_unit,
          metadata: nil,
          token_id: nil,
          address: context.alice_wallet.address
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
        request("/transaction_consumption.approve", %{
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

    test_with_auths "sends socket confirmation when require_confirmation and rejected", context do
      mint!(context.token)

      # Create a require_confirmation transaction request that will be consumed soon
      transaction_request =
        insert(
          :transaction_request,
          type: "send",
          token_uuid: context.token.uuid,
          account_uuid: context.account.uuid,
          wallet: context.account_wallet,
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
        request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: 100_000 * context.token.subunit_to_unit,
          metadata: nil,
          token_id: nil,
          provider_user_id: context.bob.provider_user_id
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
        request("/transaction_consumption.reject", %{
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
        request("/transaction_request.consume", %{
          idempotency_token: "1234",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: 100_000 * context.token.subunit_to_unit,
          metadata: nil,
          token_id: nil,
          provider_user_id: context.bob.provider_user_id
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
        request("/transaction_consumption.approve", %{
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

    defp assert_consume_logs(logs, originator, transaction_consumption) do
      transaction =
        Transaction
        |> get_last_inserted()
        |> Repo.preload([
          :from_account,
          :from_token,
          :from_wallet,
          :to_wallet,
          :to_user,
          :to_token
        ])

      alice_account_user = AccountUser |> get_last_inserted() |> Repo.preload(:user)

      assert Enum.count(logs) == 8

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: originator,
        target: transaction_consumption,
        changes: %{
          "account_uuid" => transaction_consumption.account.uuid,
          "estimated_at" => DateFormatter.to_iso8601(transaction_consumption.estimated_at),
          "estimated_consumption_amount" => transaction_consumption.estimated_consumption_amount,
          "estimated_rate" => transaction_consumption.estimated_rate,
          "estimated_request_amount" => transaction_consumption.estimated_request_amount,
          "idempotency_token" => transaction_consumption.idempotency_token,
          "token_uuid" => transaction_consumption.token.uuid,
          "transaction_request_uuid" => transaction_consumption.transaction_request.uuid,
          "wallet_address" => transaction_consumption.wallet_address
        },
        encrypted_changes: %{}
      )

      logs
      |> Enum.at(1)
      |> assert_activity_log(
        action: "update",
        originator: :system,
        target: transaction_consumption,
        changes: %{
          "approved_at" => DateFormatter.to_iso8601(transaction_consumption.approved_at),
          "status" => "approved"
        },
        encrypted_changes: %{}
      )

      logs
      |> Enum.at(2)
      |> assert_activity_log(
        action: "insert",
        originator: transaction_consumption,
        target: transaction,
        changes: %{
          "calculated_at" => DateFormatter.to_iso8601(transaction.calculated_at),
          "from" => transaction.from_wallet.address,
          "from_amount" => 10_000_000,
          "from_account_uuid" => transaction.from_account.uuid,
          "from_token_uuid" => transaction.from_token.uuid,
          "idempotency_token" => transaction.idempotency_token,
          "to" => transaction.to_wallet.address,
          "to_user_uuid" => transaction.to_user.uuid,
          "to_amount" => 10_000_000,
          "to_token_uuid" => transaction.to_token.uuid,
          "rate" => transaction.rate
        },
        encrypted_changes: %{
          "payload" => %{
            "encrypted_metadata" => %{},
            "exchange_account_id" => nil,
            "exchange_wallet_address" => nil,
            "from_address" => transaction.from_wallet.address,
            "from_amount" => 10_000_000,
            "from_token_id" => transaction.from_token.id,
            "idempotency_token" => transaction.idempotency_token,
            "metadata" => %{},
            "to_address" => transaction.to_wallet.address,
            "to_amount" => 10_000_000,
            "to_token_id" => transaction.to_token.id
          }
        }
      )

      logs
      |> Enum.at(3)
      |> assert_activity_log(
        action: "insert",
        originator: transaction,
        target: alice_account_user,
        changes: %{
          "account_uuid" => alice_account_user.account_uuid,
          "user_uuid" => alice_account_user.user.uuid
        },
        encrypted_changes: %{}
      )

      logs
      |> Enum.at(4)
      |> assert_activity_log(
        action: "update",
        originator: :system,
        target: transaction,
        changes: %{
          "local_ledger_uuid" => transaction.local_ledger_uuid,
          "status" => "confirmed"
        },
        encrypted_changes: %{}
      )

      logs
      |> Enum.at(5)
      |> assert_activity_log(
        action: "update",
        originator: transaction,
        target: transaction_consumption,
        changes: %{
          "confirmed_at" => DateFormatter.to_iso8601(transaction_consumption.confirmed_at),
          "status" => "confirmed",
          "transaction_uuid" => transaction.uuid
        },
        encrypted_changes: %{}
      )

      logs
      |> Enum.at(6)
      |> assert_activity_log(
        action: "update",
        originator: :system,
        target: transaction_consumption.transaction_request,
        changes: %{"consumptions_count" => 1},
        encrypted_changes: %{}
      )

      logs
      |> Enum.at(7)
      |> assert_activity_log(
        action: "update",
        originator: :system,
        target: transaction_consumption.transaction_request,
        changes: %{
          "updated_at" =>
            DateFormatter.to_iso8601(transaction_consumption.transaction_request.updated_at)
        },
        encrypted_changes: %{}
      )
    end

    test "generates an activity log with an admin request", context do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: context.token.uuid,
          user_uuid: context.alice.uuid,
          wallet: context.alice_wallet,
          amount: 100_000 * context.token.subunit_to_unit
        )

      set_initial_balance(%{
        address: context.bob_wallet.address,
        token: context.token,
        amount: 150_000
      })

      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil,
          account_id: context.account.id
        })

      assert response["success"] == true

      transaction_consumption =
        response["data"]["id"]
        |> TransactionConsumption.get()
        |> Repo.preload([:account, :transaction_request, :token])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_consume_logs(get_test_admin(), transaction_consumption)
    end

    test "generates an activity log with a provider request", context do
      transaction_request =
        insert(
          :transaction_request,
          type: "receive",
          token_uuid: context.token.uuid,
          user_uuid: context.alice.uuid,
          wallet: context.alice_wallet,
          amount: 100_000 * context.token.subunit_to_unit
        )

      set_initial_balance(%{
        address: context.bob_wallet.address,
        token: context.token,
        amount: 150_000
      })

      timestamp = DateTime.utc_now()

      response =
        provider_request("/transaction_request.consume", %{
          idempotency_token: "123",
          formatted_transaction_request_id: transaction_request.id,
          correlation_id: nil,
          amount: nil,
          address: nil,
          metadata: nil,
          token_id: nil,
          account_id: context.account.id
        })

      assert response["success"] == true

      transaction_consumption =
        response["data"]["id"]
        |> TransactionConsumption.get()
        |> Repo.preload([:account, :transaction_request, :token])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_consume_logs(get_test_key(), transaction_consumption)
    end
  end
end
