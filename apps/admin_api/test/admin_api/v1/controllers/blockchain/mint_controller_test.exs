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

defmodule AdminAPI.V1.Blockchain.MintControllerTest do
  use AdminAPI.ConnCase, async: false
  alias EWalletDB.{Account, Mint, Repo, Transaction}

  describe "/token.mint" do
    @big_number 100_000_000_000_000_000_000_000_000_000_000_000 - 1

    test_with_auths "mints an existing ERC20 token", context do
      enable_blockchain(context)

      token = insert(:internal_blockchain_token)

      response =
        request("/token.mint", %{
          id: token.id,
          amount: 1_000_000 * token.subunit_to_unit
        })

      assert_mint(:existing_token, token, response)
    end

    test_with_auths "mints an existing ERC20 token with string amount", context do
      enable_blockchain(context)
      token = insert(:internal_blockchain_token)

      response =
        request("/token.mint", %{
          id: token.id,
          amount: "100000000"
        })

      assert_mint(:existing_token, token, response)
    end

    test_with_auths "mints an existing ERC20 token with a big number", context do
      enable_blockchain(context)
      token = insert(:internal_blockchain_token)

      response =
        request("/token.mint", %{
          id: token.id,
          amount: @big_number
        })

      mint = Mint |> Repo.all() |> Enum.at(0)

      assert response["success"]
      assert response["data"]["object"] == "mint"
      assert Mint.get(response["data"]["id"]) != nil
      assert mint != nil
      assert mint.amount == @big_number
      assert mint.token_uuid == token.uuid
    end

    test_with_auths "fails to mint an existing ERC20 token with amount = nil", context do
      enable_blockchain(context)
      token = insert(:internal_blockchain_token)

      response =
        request("/token.mint", %{
          id: token.id,
          amount: nil
        })

      refute response["success"]
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided."
    end

    test_with_auths "fails to mint a locked existing ERC20 token", context do
      enable_blockchain(context)
      token = insert(:internal_blockchain_token, locked: true)

      response =
        request("/token.mint", %{
          id: token.id,
          amount: "100000000"
        })

      mint = Mint |> Repo.all() |> Enum.at(0)
      refute response["success"]
      assert response["data"]["code"] == "token:is_locked"
      assert response["data"]["description"] == "Minting is not allowed for this token."
      assert mint == nil
    end

    test_with_auths "fails to mint an existing ERC20 token with mint amount sent as string",
                    context do
      enable_blockchain(context)
      token = insert(:internal_blockchain_token)

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

    test_with_auths "fails to mint an existing ERC20 token with mint amount == 0", context do
      enable_blockchain(context)
      token = insert(:internal_blockchain_token)

      response =
        request("/token.mint", %{
          id: token.id,
          amount: 0
        })

      assert_mint(:fails_with_amount_zero_or_less, response)
    end

    test_with_auths "fails to mint an existing ERC20 token with mint amount < 0", context do
      enable_blockchain(context)
      token = insert(:internal_blockchain_token)

      response =
        request("/token.mint", %{
          id: token.id,
          amount: -1
        })

      assert_mint(:fails_with_amount_zero_or_less, response)
    end

    test "generates an activity log for an admin request", context do
      enable_blockchain(context)
      token = insert(:internal_blockchain_token)
      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/token.mint", %{
          id: token.id,
          amount: 1000
        })

      assert response["success"] == true

      mint = response["data"]["id"] |> Mint.get() |> Repo.preload([:account, :token])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_mint_logs(get_test_admin(), mint)
    end

    test "generates an activity log for a provider request", context do
      enable_blockchain(context)
      account = Account.get_master_account()
      token = insert(:internal_blockchain_token, account: account)
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

  defp assert_mint(:existing_token, token, response) do
    mint = Mint |> Repo.all() |> Enum.at(0)

    assert response["success"]
    assert response["data"]["object"] == "mint"
    assert Mint.get(response["data"]["id"]) != nil
    assert mint != nil
    assert mint.amount == 1_000_000 * token.subunit_to_unit
    assert mint.token_uuid == token.uuid
  end

  defp assert_mint(:fails_with_amount_zero_or_less, response) do
    refute response["success"]
    assert response["data"]["object"] == "error"
    assert response["data"]["code"] == "client:invalid_parameter"

    assert response["data"]["description"] ==
             "Invalid parameter provided. `amount` must be greater than 0."
  end

  defp assert_mint_logs(logs, originator, mint) do
    transaction =
      Transaction
      |> get_last_inserted()
      |> Repo.preload([:blockchain_transaction, :from_token, :to_token])

    assert Enum.count(logs) == 4

    logs
    |> Enum.at(0)
    |> assert_activity_log(
      action: "insert",
      originator: :system,
      target: transaction.blockchain_transaction,
      changes: %{
        "gas_limit" => transaction.blockchain_transaction.gas_limit,
        "gas_price" => transaction.blockchain_transaction.gas_price,
        "hash" => transaction.blockchain_transaction.hash,
        "rootchain_identifier" => transaction.blockchain_transaction.rootchain_identifier
      },
      encrypted_changes: %{}
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
      originator: mint,
      target: transaction,
      changes: %{
        "blockchain_transaction_uuid" => transaction.blockchain_transaction_uuid,
        "from_amount" => transaction.payload["amount"],
        "from_blockchain_address" => transaction.payload["hot_wallet_address"],
        "from_token_uuid" => transaction.from_token.uuid,
        "idempotency_token" => transaction.idempotency_token,
        "status" => transaction.status,
        "to_amount" => transaction.payload["amount"],
        "to_blockchain_address" => transaction.payload["contract_address"],
        "to_token_uuid" => transaction.to_token.uuid,
        "type" => transaction.type
      },
      encrypted_changes: %{
        "payload" => %{
          "amount" => transaction.payload["amount"],
          "blockchain_transaction_uuid" => transaction.blockchain_transaction_uuid,
          "contract_address" => transaction.payload["contract_address"],
          "hot_wallet_address" => transaction.payload["hot_wallet_address"],
          "id" => transaction.payload["id"],
          "token_id" => transaction.payload["token_id"]
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
  end
end
