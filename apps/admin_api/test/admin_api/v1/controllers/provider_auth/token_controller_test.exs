defmodule AdminAPI.V1.ProviderAuth.TokenControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.Web.V1.TokenSerializer
  alias EWalletDB.{Mint, Repo, Token, Account, Wallet, Transaction}
  alias ActivityLogger.System

  describe "/token.all" do
    test "returns a list of tokens and pagination data" do
      response = provider_request("/token.all")

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

    test "returns a list of tokens and pagination data as a provider" do
      response = provider_request("/token.all")

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

    test "returns a list of tokens according to search_term, sort_by and sort_direction" do
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

      response = provider_request("/token.all", attrs)
      tokens = response["data"]["data"]

      assert response["success"]
      assert Enum.count(tokens) == 3
      assert Enum.at(tokens, 0)["symbol"] == "XYZ3"
      assert Enum.at(tokens, 1)["symbol"] == "XYZ2"
      assert Enum.at(tokens, 2)["symbol"] == "XYZ1"
    end

    test_supports_match_any("/token.all", :provider_auth, :token, :name)
    test_supports_match_all("/token.all", :provider_auth, :token, :name)
  end

  describe "/token.get" do
    test "returns a token by the given ID" do
      tokens = insert_list(3, :token)
      # Pick the 2nd inserted token
      target = Enum.at(tokens, 1)
      response = provider_request("/token.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "token"
      assert response["data"]["id"] == target.id
    end

    test "returns 'token:id_not_found' if the given ID was not found" do
      response = provider_request("/token.get", %{"id" => "wrong_id"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "token:id_not_found"

      assert response["data"]["description"] ==
               "There is no token corresponding to the provided id."
    end

    test "returns 'client:invalid_parameter' if id was not provided" do
      response = provider_request("/token.get", %{"not_id" => "token_id"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided."
    end
  end

  describe "/token.stats" do
    test "returns the stats for a token" do
      token = insert(:token)
      _mints = insert_list(3, :mint, token_uuid: token.uuid, amount: 100_000)
      response = provider_request("/token.stats", %{"id" => token.id})

      assert response["success"]

      assert response["data"] == %{
               "object" => "token_stats",
               "token_id" => token.id,
               "token" => token |> TokenSerializer.serialize() |> stringify_keys(),
               "total_supply" => 300_000
             }
    end

    test "return token_not_found for non existing tokens" do
      token = insert(:token)
      _mints = insert_list(3, :mint, token_uuid: token.uuid)
      response = provider_request("/token.stats", %{"id" => "fale"})

      assert response["success"] == false

      assert response["data"] == %{
               "object" => "error",
               "code" => "token:id_not_found",
               "description" => "There is no token corresponding to the provided id.",
               "messages" => nil
             }
    end
  end

  describe "/token.create" do
    test "inserts a new token" do
      response =
        provider_request("/token.create", %{
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

    test "inserts a new token with no minting if amount is nil" do
      response =
        provider_request("/token.create", %{
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

    test "inserts a new token with minting if amount is a string" do
      response =
        provider_request("/token.create", %{
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

    test "fails to create new token with no minting if amount is 0" do
      response =
        provider_request("/token.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100,
          amount: 0
        })

      mint = Mint |> Repo.all() |> Enum.at(0)
      assert mint == nil
      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid amount provided: '0'."
    end

    test "mints the given amount of tokens" do
      response =
        provider_request("/token.create", %{
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

    test "returns insert error when attrs are invalid" do
      response =
        provider_request("/token.create", %{
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

    test "generates an activity log" do
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

      token = Token.get(response["data"]["id"])
      account = Account.get_master_account()
      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: get_test_key(),
        target: token,
        changes: %{
          "name" => "Bitcoin",
          "account_uuid" => account.uuid,
          "description" => "desc",
          "id" => token.id,
          "metadata" => %{"something" => "interesting"},
          "subunit_to_unit" => 100,
          "symbol" => "BTC"
        },
        encrypted_changes: %{"encrypted_metadata" => %{"something" => "secret"}}
      )
    end

    test "generates an activity log when minting" do
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

      token = Token.get(response["data"]["id"])
      account = Account.get_master_account()
      wallet = Account.get_primary_wallet(account)
      genesis = Wallet.get("gnis000000000000")
      mint = Mint |> Repo.all() |> Enum.at(0)
      transaction = get_last_inserted(Transaction)
      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 7

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: get_test_key(),
        target: token,
        changes: %{
          "name" => "Bitcoin",
          "account_uuid" => account.uuid,
          "description" => "desc",
          "id" => token.id,
          "metadata" => %{"something" => "interesting"},
          "subunit_to_unit" => 100,
          "symbol" => "BTC"
        },
        encrypted_changes: %{"encrypted_metadata" => %{"something" => "secret"}}
      )

      logs
      |> Enum.at(1)
      |> assert_activity_log(
        action: "insert",
        originator: get_test_key(),
        target: mint,
        changes: %{
          "account_uuid" => account.uuid,
          "amount" => 100,
          "token_uuid" => token.uuid
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
          "from_token_uuid" => token.uuid,
          "idempotency_token" => transaction.idempotency_token,
          "to" => wallet.address,
          "to_account_uuid" => account.uuid,
          "to_amount" => 100,
          "to_token_uuid" => token.uuid
        },
        encrypted_changes: %{
          "payload" => %{
            "amount" => 100,
            "description" => nil,
            "idempotency_token" => transaction.idempotency_token,
            "token_id" => token.id
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
  end

  describe "/token.update" do
    test "updates an existing token" do
      token = insert(:token)

      response =
        provider_request("/token.update", %{
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

    test "Raises invalid_parameter error if id is missing" do
      response = provider_request("/token.update", %{name: "Bitcoin"})

      refute response["success"]

      assert response["data"] == %{
               "object" => "error",
               "code" => "client:invalid_parameter",
               "description" => "Invalid parameter provided. `id` is required.",
               "messages" => nil
             }
    end

    test "Raises token_not_found error if the token can't be found" do
      response = provider_request("/token.update", %{id: "fake", name: "Bitcoin"})

      refute response["success"]

      assert response["data"] == %{
               "object" => "error",
               "code" => "token:id_not_found",
               "description" => "There is no token corresponding to the provided id.",
               "messages" => nil
             }
    end

    test "generates an activity log" do
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
      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: get_test_key(),
        target: token,
        changes: %{
          "metadata" => %{"something" => "interesting"},
          "description" => "updated description",
          "name" => "updated name"
        },
        encrypted_changes: %{"encrypted_metadata" => %{"something" => "secret"}}
      )
    end
  end

  describe "/token.enable_or_disable" do
    test "disables an existing token" do
      token = insert(:token)

      response =
        provider_request("/token.enable_or_disable", %{
          id: token.id,
          enabled: false
        })

      assert response["success"]
      assert response["data"]["object"] == "token"
      assert response["data"]["enabled"] == false
    end

    test "fails to disable an existing token with enabled = nil" do
      token = insert(:token)

      response =
        provider_request("/token.enable_or_disable", %{
          id: token.id,
          enabled: nil
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `enabled` can't be blank."
    end

    test "Raises invalid_parameter error if id is missing" do
      response =
        provider_request("/token.enable_or_disable", %{enabled: false, originator: %System{}})

      refute response["success"]

      assert response["data"] == %{
               "object" => "error",
               "code" => "client:invalid_parameter",
               "description" => "Invalid parameter provided. `id` is required.",
               "messages" => nil
             }
    end

    test "Raises token_not_found error if the token can't be found" do
      response = provider_request("/token.enable_or_disable", %{id: "fake", enabled: false})

      refute response["success"]

      assert response["data"] == %{
               "object" => "error",
               "code" => "token:id_not_found",
               "description" => "There is no token corresponding to the provided id.",
               "messages" => nil
             }
    end

    test "generates an activity log" do
      token = insert(:token)

      timestamp = DateTime.utc_now()

      response =
        provider_request("/token.enable_or_disable", %{
          id: token.id,
          enabled: false
        })

      assert response["success"] == true

      token = Token.get(token.id)
      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: get_test_key(),
        target: token,
        changes: %{
          "enabled" => false
        },
        encrypted_changes: %{}
      )
    end
  end
end
