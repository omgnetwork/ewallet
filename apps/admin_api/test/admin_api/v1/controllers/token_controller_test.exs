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

defmodule AdminAPI.V1.TokenControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.Web.V1.TokenSerializer
  alias EWalletDB.{Mint, Repo, Token, Wallet, Transaction}
  alias ActivityLogger.System

  describe "/token.all" do
    test_with_auths "returns a list of tokens and pagination data" do
      response = request("/token.all")

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

    test_with_auths "returns a list of tokens and pagination data as a provider" do
      response = request("/token.all")

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

    test_with_auths "returns a list of tokens according to search_term, sort_by and sort_direction" do
      insert(:token, %{symbol: "XYZ1"})
      insert(:token, %{symbol: "XYZ3"})
      insert(:token, %{symbol: "XYZ2"})
      insert(:token, %{symbol: "ZZZ1"})

      attrs = %{
        # Search is case-insensitive
        "search_term" => "xYz",
        "sort_by" => "symbol",
        "sort_dir" => "desc"
      }

      response = request("/token.all", attrs)
      tokens = response["data"]["data"]

      assert response["success"]
      assert Enum.count(tokens) == 3
      assert Enum.at(tokens, 0)["symbol"] == "XYZ3"
      assert Enum.at(tokens, 1)["symbol"] == "XYZ2"
      assert Enum.at(tokens, 2)["symbol"] == "XYZ1"
    end

    test_supports_match_any("/token.all", :token, :name)
    test_supports_match_all("/token.all", :token, :name)
  end

  describe "/token.get" do
    test_with_auths "returns a token by the given ID" do
      tokens = insert_list(3, :token)
      # Pick the 2nd inserted token
      target = Enum.at(tokens, 1)
      response = request("/token.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "token"
      assert response["data"]["id"] == target.id
    end

    test_with_auths "returns 'token:id_not_found' if the given ID was not found" do
      response = request("/token.get", %{"id" => "wrong_id"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "token:id_not_found"

      assert response["data"]["description"] ==
               "There is no token corresponding to the provided id."
    end

    test_with_auths "returns 'client:invalid_parameter' if id was not provided" do
      response = request("/token.get", %{"not_id" => "token_id"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided."
    end
  end

  describe "/token.stats" do
    test_with_auths "returns the stats for a token" do
      token = insert(:token)
      _mints = insert_list(3, :mint, token_uuid: token.uuid, amount: 100_000)
      response = request("/token.stats", %{"id" => token.id})
      assert response["success"]

      assert response["data"] == %{
               "object" => "token_stats",
               "token_id" => token.id,
               "token" => token |> TokenSerializer.serialize() |> stringify_keys(),
               "total_supply" => 300_000
             }
    end

    test_with_auths "return token_not_found for non existing tokens" do
      token = insert(:token)
      _mints = insert_list(3, :mint, token_uuid: token.uuid)
      response = request("/token.stats", %{"id" => "fale"})

      assert response["success"] == false

      assert response["data"] == %{
               "object" => "error",
               "code" => "token:id_not_found",
               "description" => "There is no token corresponding to the provided id.",
               "messages" => nil
             }
    end

    test_with_auths "returns the stats for a token that hasn't been minted" do
      token = insert(:token)
      response = request("/token.stats", %{"id" => token.id})
      assert response["success"]

      assert response["data"] == %{
               "object" => "token_stats",
               "token_id" => token.id,
               "token" => token |> TokenSerializer.serialize() |> stringify_keys(),
               "total_supply" => 0
             }
    end
  end

  describe "/token.create" do
    test_with_auths "inserts a new token" do
      response =
        request("/token.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100,
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      mint = Mint |> Repo.all() |> Enum.at(0)

      assert response["success"]
      assert response["data"]["object"] == "token"
      assert response["data"]["metadata"] == %{"something" => "interesting"}
      assert response["data"]["encrypted_metadata"] == %{"something" => "secret"}
      assert Token.get(response["data"]["id"]) != nil
      assert mint == nil
    end

    test_with_auths "returns an error with decimals > 18 (19 decimals)" do
      response =
        request("/token.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          subunit_to_unit: 10_000_000_000_000_000_000_000
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test_with_auths "inserts a new token with no minting if amount is nil" do
      response =
        request("/token.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100,
          amount: nil
        })

      mint = Mint |> Repo.all() |> Enum.at(0)

      assert response["success"]
      assert response["data"]["object"] == "token"
      assert Token.get(response["data"]["id"]) != nil
      assert mint == nil
    end

    test_with_auths "fails a new token with no minting if amount is 0" do
      response =
        request("/token.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100,
          amount: 0
        })

      mint = Mint |> Repo.all() |> Enum.at(0)
      assert mint == nil
      assert response["success"] == false
    end

    test_with_auths "mints the given amount of tokens" do
      response =
        request("/token.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100,
          amount: 1_000 * 100
        })

      mint = Mint |> Repo.all() |> Enum.at(0)

      assert response["success"]
      assert response["data"]["object"] == "token"
      assert Token.get(response["data"]["id"]) != nil
      assert mint != nil
      assert mint.confirmed == true
    end

    test_with_auths "inserts a new token with minting if amount is a string" do
      response =
        request("/token.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100,
          amount: "100"
        })

      mint = Mint |> Repo.all() |> Enum.at(0)

      assert response["success"]
      assert response["data"]["object"] == "token"
      assert Token.get(response["data"]["id"]) != nil
      assert mint != nil
      assert mint.confirmed == true
    end

    test_with_auths "returns insert error when attrs are invalid" do
      response =
        request("/token.create", %{
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100
        })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `symbol` can't be blank."

      inserted = Token |> Repo.all() |> Enum.at(0)
      assert inserted == nil
    end

    defp assert_create_logs(logs, originator, target) do
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: originator,
        target: target,
        changes: %{
          "name" => target.name,
          "account_uuid" => target.account.uuid,
          "description" => target.description,
          "id" => target.id,
          "metadata" => target.metadata,
          "subunit_to_unit" => target.subunit_to_unit,
          "symbol" => target.symbol
        },
        encrypted_changes: %{"encrypted_metadata" => target.encrypted_metadata}
      )
    end

    test "generates an activity log for an admin request" do
      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/token.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100,
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      assert response["success"] == true

      token = response["data"]["id"] |> Token.get() |> Repo.preload(:account)

      timestamp
      |> get_all_activity_logs_since()
      |> assert_create_logs(get_test_admin(), token)
    end

    test "generates an activity log for a provider request" do
      timestamp = DateTime.utc_now()

      response =
        provider_request("/token.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100,
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      assert response["success"] == true

      token = response["data"]["id"] |> Token.get() |> Repo.preload(:account)

      timestamp
      |> get_all_activity_logs_since()
      |> assert_create_logs(get_test_key(), token)
    end

    defp assert_create_minting_logs(logs, originator, token: token, mint: mint) do
      genesis = Wallet.get("gnis000000000000")

      transaction =
        Transaction
        |> get_last_inserted()
        |> Repo.preload([:from_token, :to_wallet, :to_account, :to_token])

      assert Enum.count(logs) == 7

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: originator,
        target: token,
        changes: %{
          "name" => token.name,
          "account_uuid" => token.account.uuid,
          "description" => token.description,
          "id" => token.id,
          "metadata" => token.metadata,
          "subunit_to_unit" => token.subunit_to_unit,
          "symbol" => token.symbol
        },
        encrypted_changes: %{"encrypted_metadata" => token.encrypted_metadata}
      )

      logs
      |> Enum.at(1)
      |> assert_activity_log(
        action: "insert",
        originator: originator,
        target: mint,
        changes: %{
          "account_uuid" => mint.account.uuid,
          "amount" => mint.amount,
          "token_uuid" => mint.token.uuid
        },
        encrypted_changes: %{}
      )

      logs
      |> Enum.at(2)
      |> assert_activity_log(
        action: "insert",
        originator: :system,
        target: genesis,
        changes: %{
          "address" => "gnis000000000000",
          "identifier" => "genesis",
          "name" => "genesis"
        },
        encrypted_changes: %{}
      )

      logs
      |> Enum.at(3)
      |> assert_activity_log(
        action: "insert",
        originator: mint,
        target: transaction,
        changes: %{
          "from" => "gnis000000000000",
          "from_amount" => 100,
          "from_token_uuid" => transaction.from_token.uuid,
          "idempotency_token" => transaction.idempotency_token,
          "to" => transaction.to_wallet.address,
          "to_account_uuid" => transaction.to_account.uuid,
          "to_amount" => 100,
          "to_token_uuid" => transaction.to_token.uuid
        },
        encrypted_changes: %{
          "payload" => %{
            "amount" => 100,
            "description" => nil,
            "idempotency_token" => transaction.idempotency_token,
            "token_id" => transaction.to_token.id
          }
        }
      )

      logs
      |> Enum.at(4)
      |> assert_activity_log(
        action: "update",
        originator: transaction,
        target: mint,
        changes: %{
          "transaction_uuid" => transaction.uuid
        },
        encrypted_changes: %{}
      )

      logs
      |> Enum.at(5)
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
      |> Enum.at(6)
      |> assert_activity_log(
        action: "update",
        originator: transaction,
        target: mint,
        changes: %{"confirmed" => true},
        encrypted_changes: %{}
      )
    end

    test "generates an activity log when minting for an admin request" do
      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/token.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100,
          amount: 100,
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      assert response["success"] == true

      token = response["data"]["id"] |> Token.get() |> Repo.preload(:account)

      mint = Mint |> get_last_inserted() |> Repo.preload([:account, :token])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_create_minting_logs(get_test_admin(), token: token, mint: mint)
    end

    test "generates an activity log when minting for a provider request" do
      timestamp = DateTime.utc_now()

      response =
        provider_request("/token.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100,
          amount: 100,
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      assert response["success"] == true

      token = response["data"]["id"] |> Token.get() |> Repo.preload(:account)

      mint = Mint |> get_last_inserted() |> Repo.preload([:account, :token])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_create_minting_logs(get_test_key(), token: token, mint: mint)
    end
  end

  describe "/token.update" do
    test_with_auths "updates an existing token" do
      token = insert(:token)

      response =
        request("/token.update", %{
          id: token.id,
          name: "updated name",
          description: "updated description",
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      assert response["success"]
      assert response["data"]["object"] == "token"
      assert response["data"]["name"] == "updated name"
      assert response["data"]["metadata"] == %{"something" => "interesting"}
      assert response["data"]["encrypted_metadata"] == %{"something" => "secret"}
    end

    test_with_auths "fails to update an existing token with name = nil" do
      token = insert(:token)

      response =
        request("/token.update", %{
          id: token.id,
          name: nil
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `name` can't be blank."
    end

    test_with_auths "Raises invalid_parameter error if id is missing" do
      response = request("/token.update", %{name: "Bitcoin"})

      refute response["success"]

      assert response["data"] == %{
               "object" => "error",
               "code" => "client:invalid_parameter",
               "description" => "Invalid parameter provided. `id` is required.",
               "messages" => nil
             }
    end

    test_with_auths "Raises token_not_found error if the token can't be found" do
      response = request("/token.update", %{id: "fake", name: "Bitcoin"})

      refute response["success"]

      assert response["data"] == %{
               "object" => "error",
               "code" => "token:id_not_found",
               "description" => "There is no token corresponding to the provided id.",
               "messages" => nil
             }
    end

    defp assert_update_logs(logs, originator, target) do
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: originator,
        target: target,
        changes: %{
          "metadata" => target.metadata,
          "description" => target.description,
          "name" => target.name
        },
        encrypted_changes: %{"encrypted_metadata" => target.encrypted_metadata}
      )
    end

    test "generates an activity log for an admin request" do
      token = insert(:token)

      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/token.update", %{
          id: token.id,
          name: "updated name",
          description: "updated description",
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      assert response["success"] == true

      token = Token.get(token.id)

      timestamp |> get_all_activity_logs_since() |> assert_update_logs(get_test_admin(), token)
    end

    test "generates an activity log for a provider request" do
      token = insert(:token)

      timestamp = DateTime.utc_now()

      response =
        provider_request("/token.update", %{
          id: token.id,
          name: "updated name",
          description: "updated description",
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      assert response["success"] == true

      token = Token.get(token.id)

      timestamp |> get_all_activity_logs_since() |> assert_update_logs(get_test_key(), token)
    end
  end

  describe "/token.enable_or_disable" do
    test_with_auths "disables an existing token" do
      token = insert(:token)

      response =
        request("/token.enable_or_disable", %{
          id: token.id,
          enabled: false
        })

      assert response["success"]
      assert response["data"]["object"] == "token"
      assert response["data"]["enabled"] == false
    end

    test_with_auths "fails to disable an existing token with enabled = nil" do
      token = insert(:token)

      response =
        request("/token.enable_or_disable", %{
          id: token.id,
          enabled: nil
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `enabled` can't be blank."
    end

    test_with_auths "Raises invalid_parameter error if id is missing" do
      response = request("/token.enable_or_disable", %{enabled: false, originator: %System{}})

      refute response["success"]

      assert response["data"] == %{
               "object" => "error",
               "code" => "client:invalid_parameter",
               "description" => "Invalid parameter provided. `id` is required.",
               "messages" => nil
             }
    end

    test_with_auths "Raises token_not_found error if the token can't be found" do
      response = request("/token.enable_or_disable", %{id: "fake", enabled: false})

      refute response["success"]

      assert response["data"] == %{
               "object" => "error",
               "code" => "token:id_not_found",
               "description" => "There is no token corresponding to the provided id.",
               "messages" => nil
             }
    end

    defp assert_enable_logs(logs, originator, target) do
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: originator,
        target: target,
        changes: %{
          "enabled" => target.enabled
        },
        encrypted_changes: %{}
      )
    end

    test "generates an activity log for an admin request" do
      token = insert(:token)

      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/token.enable_or_disable", %{
          id: token.id,
          enabled: false
        })

      assert response["success"] == true

      token = Token.get(token.id)

      timestamp |> get_all_activity_logs_since() |> assert_enable_logs(get_test_admin(), token)
    end

    test "generates an activity log for a provider request" do
      token = insert(:token)

      timestamp = DateTime.utc_now()

      response =
        provider_request("/token.enable_or_disable", %{
          id: token.id,
          enabled: false
        })

      assert response["success"] == true

      token = Token.get(token.id)

      timestamp |> get_all_activity_logs_since() |> assert_enable_logs(get_test_key(), token)
    end
  end
end
