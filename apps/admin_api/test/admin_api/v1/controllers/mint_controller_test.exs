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

defmodule AdminAPI.V1.MintControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.MintGate
  alias Utils.Helpers.DateFormatter
  alias EWallet.Web.V1.{AccountSerializer, TokenSerializer, TransactionSerializer}
  alias EWalletDB.{Mint, Transaction, Wallet, Repo}
  alias ActivityLogger.System

  describe "/token.get_mints" do
    test_with_auths "returns a list of mints and pagination data" do
      token = insert(:token)

      {:ok, inserted_mint, _} =
        MintGate.insert(%{
          "idempotency_token" => "123",
          "token_id" => token.id,
          "amount" => 100_000,
          "description" => "desc.",
          "originator" => %System{}
        })

      inserted_mint = Repo.preload(inserted_mint, [:account, :token, :transaction])

      {:ok, _, _} =
        MintGate.insert(%{
          "idempotency_token" => "123",
          "token_id" => token.id,
          "amount" => 100_000,
          "description" => "desc.",
          "originator" => %System{}
        })

      response =
        request("/token.get_mints", %{
          "id" => token.id,
          "sort_by" => "asc",
          "sort" => "created_at"
        })

      # Asserts return data
      assert response["success"]
      assert response["data"]["object"] == "list"
      assert is_list(response["data"]["data"])
      assert length(response["data"]["data"]) == 2

      Enum.member?(response["data"]["data"], %{
        "account" => inserted_mint.account |> AccountSerializer.serialize() |> stringify_keys(),
        "account_id" => inserted_mint.account.id,
        "amount" => 100_000,
        "confirmed" => true,
        "description" => "desc.",
        "id" => inserted_mint.id,
        "object" => "mint",
        "token" => inserted_mint.token |> TokenSerializer.serialize() |> stringify_keys(),
        "token_id" => inserted_mint.token.id,
        "transaction" =>
          inserted_mint.transaction |> TransactionSerializer.serialize() |> stringify_keys(),
        "transaction_id" => inserted_mint.transaction.id,
        "created_at" => DateFormatter.to_iso8601(inserted_mint.inserted_at),
        "updated_at" => DateFormatter.to_iso8601(inserted_mint.updated_at)
      })

      # Asserts pagination data
      pagination = response["data"]["pagination"]
      assert is_integer(pagination["per_page"])
      assert is_integer(pagination["current_page"])
      assert is_boolean(pagination["is_last_page"])
      assert is_boolean(pagination["is_first_page"])
    end

    test_with_auths "returns a list of mints according to search_term, sort_by and sort_direction" do
      token = insert(:token)

      insert(:mint, %{token_uuid: token.uuid, description: "XYZ1"})
      insert(:mint, %{token_uuid: token.uuid, description: "XYZ3"})
      insert(:mint, %{token_uuid: token.uuid, description: "XYZ2"})

      attrs = %{
        # Search is case-insensitive
        "id" => token.id,
        "search_term" => "xYz",
        "sort_by" => "description",
        "sort_dir" => "desc"
      }

      response = request("/token.get_mints", attrs)

      mints = response["data"]["data"]

      assert response["success"]
      assert Enum.count(mints) == 3
      assert Enum.at(mints, 0)["description"] == "XYZ3"
      assert Enum.at(mints, 1)["description"] == "XYZ2"
      assert Enum.at(mints, 2)["description"] == "XYZ1"
    end
  end

  describe "/token.mint" do
    test_with_auths "mints an existing token" do
      token = insert(:token)

      response =
        request("/token.mint", %{
          id: token.id,
          amount: 1_000_000 * token.subunit_to_unit
        })

      mint = Mint |> Repo.all() |> Enum.at(0)

      assert response["success"]
      assert response["data"]["object"] == "mint"
      assert Mint.get(response["data"]["id"]) != nil
      assert mint != nil
      assert mint.amount == 1_000_000 * token.subunit_to_unit
      assert mint.token_uuid == token.uuid
    end

    test_with_auths "mints an existing token with string amount" do
      token = insert(:token)

      response =
        request("/token.mint", %{
          id: token.id,
          amount: "100000000"
        })

      mint = Mint |> Repo.all() |> Enum.at(0)

      assert response["success"]
      assert response["data"]["object"] == "mint"
      assert Mint.get(response["data"]["id"]) != nil
      assert mint != nil
      assert mint.amount == 1_000_000 * token.subunit_to_unit
      assert mint.token_uuid == token.uuid
    end

    test_with_auths "mints an existing token with a big number" do
      token = insert(:token)

      response =
        request("/token.mint", %{
          id: token.id,
          amount: 100_000_000_000_000_000_000_000_000_000_000_000 - 1
        })

      mint = Mint |> Repo.all() |> Enum.at(0)

      assert response["success"]
      assert response["data"]["object"] == "mint"
      assert Mint.get(response["data"]["id"]) != nil
      assert mint != nil
      assert mint.amount == 100_000_000_000_000_000_000_000_000_000_000_000 - 1
      assert mint.token_uuid == token.uuid
    end

    test_with_auths "fails to mint with amount = nil" do
      token = insert(:token)

      response =
        request("/token.mint", %{
          id: token.id,
          amount: nil
        })

      refute response["success"]
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided. Amount cannot be nil."
    end

    test_with_auths "fails to mint a non existing token" do
      response =
        request("/token.mint", %{
          id: "123",
          amount: 1_000_000
        })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "token:id_not_found"
    end

    test_with_auths "fails to mint a disabled token" do
      token = insert(:token, enabled: false)

      response =
        request("/token.mint", %{
          id: token.id,
          amount: "100000000"
        })

      mint = Mint |> Repo.all() |> Enum.at(0)

      assert response["success"] == false
      assert response["data"]["code"] == "token:disabled"
      assert mint == nil
    end

    test_with_auths "fails to mint with mint amount sent as string" do
      token = insert(:token)

      response =
        request("/token.mint", %{
          id: token.id,
          amount: "abc"
        })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. String number is not a valid number: 'abc'."
    end

    test_with_auths "fails to mint with mint amount == 0" do
      token = insert(:token)

      response =
        request("/token.mint", %{
          id: token.id,
          amount: 0
        })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `amount` must be greater than 0."

      assert response["data"]["messages"] == %{"amount" => ["number"]}
    end

    test_with_auths "fails to mint with mint amount < 0" do
      token = insert(:token)

      response =
        request("/token.mint", %{
          id: token.id,
          amount: -1
        })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `amount` must be greater than 0."

      assert response["data"]["messages"] == %{"amount" => ["number"]}
    end

    defp assert_mint_logs(logs, originator, mint) do
      genesis = Wallet.get("gnis000000000000")

      transaction =
        Transaction
        |> get_last_inserted()
        |> Repo.preload([:from_token, :to_wallet, :to_account, :to_token])

      assert Enum.count(logs) == 6

      logs
      |> Enum.at(0)
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
      |> Enum.at(1)
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
      |> Enum.at(2)
      |> assert_activity_log(
        action: "insert",
        originator: mint,
        target: transaction,
        changes: %{
          "from" => "gnis000000000000",
          "from_amount" => 100_000_000,
          "from_token_uuid" => transaction.from_token.uuid,
          "idempotency_token" => transaction.idempotency_token,
          "to" => transaction.to_wallet.address,
          "to_account_uuid" => transaction.to_account.uuid,
          "to_amount" => 100_000_000,
          "to_token_uuid" => transaction.to_token.uuid
        },
        encrypted_changes: %{
          "payload" => %{
            "amount" => 100_000_000,
            "description" => nil,
            "idempotency_token" => transaction.idempotency_token,
            "token_id" => transaction.to_token.id
          }
        }
      )

      logs
      |> Enum.at(3)
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
        target: mint,
        changes: %{"confirmed" => true},
        encrypted_changes: %{}
      )
    end

    test "generates an activity log for an admin request" do
      token = insert(:token)
      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/token.mint", %{
          id: token.id,
          amount: 1_000_000 * token.subunit_to_unit
        })

      assert response["success"] == true

      mint = response["data"]["id"] |> Mint.get() |> Repo.preload([:account, :token])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_mint_logs(get_test_admin(), mint)
    end

    test "generates an activity log for a provider request" do
      token = insert(:token)
      timestamp = DateTime.utc_now()

      response =
        provider_request("/token.mint", %{
          id: token.id,
          amount: 1_000_000 * token.subunit_to_unit
        })

      assert response["success"] == true

      mint = response["data"]["id"] |> Mint.get() |> Repo.preload([:account, :token])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_mint_logs(get_test_key(), mint)
    end
  end
end
