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

defmodule AdminAPI.V1.Blockchain.TokenControllerTest do
  use AdminAPI.ConnCase, async: false
  alias EWalletDB.{BlockchainTransaction, Mint, Repo, Token}

  describe "/token.create" do
    test_with_auths "returns an error when internal tokens are disabled", context do
      enable_blockchain(context)

      response =
        request("/token.create", %{
          symbol: "BTC",
          name: "Bitcoin",
          description: "desc",
          subunit_to_unit: 100,
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "token:internal_tokens_disabled"

      assert response["data"]["description"] ==
               "Internal tokens cannot be created."

      inserted = Token |> Repo.all() |> Enum.at(0)
      assert inserted == nil
    end
  end

  describe "/token.deploy_erc20" do
    test_with_auths "deploys a locked ERC20 token", context do
      enable_blockchain(context)

      response =
        request("/token.deploy_erc20", %{
          symbol: "BTC",
          name: "Bitcoin",
          amount: 100,
          locked: true,
          description: "desc",
          subunit_to_unit: 100
        })

      mint = Mint |> Repo.all() |> Enum.at(0)

      assert response["success"]
      assert response["data"]["object"] == "token"
      assert response["data"]["blockchain_address"] != nil
      assert response["data"]["blockchain_status"] == "pending"
      assert response["data"]["locked"] == true
      assert Token.get(response["data"]["id"]) != nil
      assert mint == nil
    end

    test_with_auths "deploys an unlocked ERC20 token", context do
      enable_blockchain(context)

      response =
        request("/token.deploy_erc20", %{
          symbol: "BTC",
          name: "Bitcoin",
          amount: 100,
          locked: false,
          description: "desc",
          subunit_to_unit: 100
        })

      mint = Mint |> Repo.all() |> Enum.at(0)

      assert response["success"]
      assert response["data"]["object"] == "token"
      assert response["data"]["blockchain_address"] != nil
      assert response["data"]["blockchain_status"] == "pending"
      assert response["data"]["locked"] == false
      assert Token.get(response["data"]["id"]) != nil
      assert mint == nil
    end

    test_with_auths "accepts `amount` parameter as string type", context do
      enable_blockchain(context)

      response =
        request("/token.deploy_erc20", %{
          symbol: "BTC",
          name: "Bitcoin",
          amount: "100000000000",
          locked: false,
          description: "desc",
          subunit_to_unit: 100
        })

      mint = Mint |> Repo.all() |> Enum.at(0)

      assert response["success"]
      assert response["data"]["object"] == "token"
      assert response["data"]["blockchain_address"] != nil
      assert response["data"]["blockchain_status"] == "pending"
      assert response["data"]["locked"] == false
      assert Token.get(response["data"]["id"]) != nil
      assert mint == nil
    end

    test_with_auths "accepts `subunit_to_unit` parameter as string or integer type", context do
      enable_blockchain(context)

      subunit_to_unit = 1_000_000_000_000_000_000

      response_1 =
        request("/token.deploy_erc20", %{
          symbol: "BTC",
          name: "Bitcoin",
          amount: 100,
          locked: false,
          description: "desc",
          subunit_to_unit: Integer.to_string(subunit_to_unit)
        })

      assert response_1["success"]
      assert response_1["data"]["subunit_to_unit"] == subunit_to_unit

      assert response_1["data"]["id"] |> Token.get() |> Map.get(:subunit_to_unit) ==
               subunit_to_unit

      response_2 =
        request("/token.deploy_erc20", %{
          symbol: "BTC",
          name: "Bitcoin",
          amount: 100,
          locked: false,
          description: "desc",
          subunit_to_unit: subunit_to_unit
        })

      assert response_2["success"]
      assert response_2["data"]["subunit_to_unit"] == subunit_to_unit

      assert response_2["data"]["id"] |> Token.get() |> Map.get(:subunit_to_unit) ==
               subunit_to_unit
    end

    test_with_auths "fails to deploys an ERC20 token with symbol = nil", context do
      enable_blockchain(context)

      response =
        request("/token.deploy_erc20", %{
          symbol: nil,
          name: "Bitcoin",
          amount: 1000,
          locked: false,
          description: "desc",
          subunit_to_unit: 100
        })

      assert_deploy_erc20(:fails_with_missing_data, response)
    end

    test_with_auths "fails to deploys an ERC20 token with name = nil", context do
      enable_blockchain(context)

      response =
        request("/token.deploy_erc20", %{
          symbol: "BTC",
          name: nil,
          amount: 1000,
          locked: false,
          description: "desc",
          subunit_to_unit: 100
        })

      assert_deploy_erc20(:fails_with_missing_data, response)
    end

    test_with_auths "fails to deploys an ERC20 token with amount = nil", context do
      enable_blockchain(context)

      response =
        request("/token.deploy_erc20", %{
          symbol: "BTC",
          name: "Bitcoin",
          amount: nil,
          locked: false,
          description: "desc",
          subunit_to_unit: 100
        })

      assert_deploy_erc20(:fails_with_missing_data, response)
    end

    test_with_auths "fails to deploys an ERC20 token with locked = nil", context do
      enable_blockchain(context)

      response =
        request("/token.deploy_erc20", %{
          symbol: "BTC",
          name: "Bitcoin",
          amount: 1000,
          locked: nil,
          description: "desc",
          subunit_to_unit: 100
        })

      assert_deploy_erc20(:fails_with_missing_data, response)
    end

    test_with_auths "fails to deploys an ERC20 token with subunit_to_unit = nil", context do
      enable_blockchain(context)

      response =
        request("/token.deploy_erc20", %{
          symbol: "BTC",
          name: "Bitcoin",
          amount: 1000,
          locked: false,
          description: "desc",
          subunit_to_unit: nil
        })

      assert_deploy_erc20(:fails_with_missing_data, response)
    end

    test_with_auths "fails to deploys an ERC20 token with amount < 0", context do
      enable_blockchain(context)

      response =
        request("/token.deploy_erc20", %{
          symbol: "BTC",
          name: "Bitcoin",
          amount: -1000,
          locked: false,
          description: "desc",
          subunit_to_unit: 100
        })

      refute response["success"]
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "`amount` must be greater than or equal to 0."
    end

    test_with_auths "fails to deploys an ERC20 token with subunit_to_unit < 0", context do
      enable_blockchain(context)

      response =
        request("/token.deploy_erc20", %{
          symbol: "BTC",
          name: "Bitcoin",
          amount: 1000,
          locked: false,
          description: "desc",
          subunit_to_unit: -1
        })

      assert_deploy_erc20(:fails_with_subunit_to_unit_zero_or_less, response)
    end

    test_with_auths "fails to deploys an ERC20 token with subunit_to_unit = 0", context do
      enable_blockchain(context)

      response =
        request("/token.deploy_erc20", %{
          symbol: "BTC",
          name: "Bitcoin",
          amount: 1000,
          locked: false,
          description: "desc",
          subunit_to_unit: 0
        })

      assert_deploy_erc20(:fails_with_subunit_to_unit_zero_or_less, response)
    end

    test "generates an activity log for an admin request", context do
      enable_blockchain(context)
      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/token.deploy_erc20", %{
          symbol: "BTC",
          name: "Bitcoin",
          amount: 100,
          locked: false,
          description: "desc",
          subunit_to_unit: 100
        })

      assert response["success"] == true

      token = response["data"]["id"] |> Token.get() |> Repo.preload(:account)

      timestamp
      |> get_all_activity_logs_since()
      |> assert_deploy_erc20_logs(get_test_admin(), token)
    end

    test "generates an activity log for a provider request", context do
      enable_blockchain(context)
      timestamp = DateTime.utc_now()

      response =
        provider_request("/token.deploy_erc20", %{
          symbol: "BTC",
          name: "Bitcoin",
          amount: 100,
          locked: false,
          description: "desc",
          subunit_to_unit: 100
        })

      assert response["success"] == true

      token = response["data"]["id"] |> Token.get() |> Repo.preload(:account)

      timestamp
      |> get_all_activity_logs_since()
      |> assert_deploy_erc20_logs(get_test_key(), token)
    end
  end

  defp assert_deploy_erc20(:fails_with_missing_data, response) do
    refute response["success"]
    assert response["data"]["code"] == "client:invalid_parameter"

    assert response["data"]["description"] ==
             "`name`, `symbol`, `subunit_to_unit`, `locked` and `amount` are required when deploying an ERC20 token."
  end

  defp assert_deploy_erc20(:fails_with_subunit_to_unit_zero_or_less, response) do
    refute response["success"]
    assert response["data"]["code"] == "client:invalid_parameter"

    assert response["data"]["description"] ==
             "`subunit_to_unit` must be greater than 0."
  end

  defp assert_deploy_erc20_logs(logs, originator, target) do
    blockchain_transaction = get_last_inserted(BlockchainTransaction)

    assert Enum.count(logs) == 2

    logs
    |> Enum.at(0)
    |> assert_activity_log(
      action: "insert",
      originator: :system,
      target: blockchain_transaction,
      changes: %{
        "gas_limit" => blockchain_transaction.gas_limit,
        "gas_price" => blockchain_transaction.gas_price,
        "hash" => blockchain_transaction.hash,
        "rootchain_identifier" => blockchain_transaction.rootchain_identifier
      },
      encrypted_changes: %{}
    )

    logs
    |> Enum.at(1)
    |> assert_activity_log(
      action: "insert",
      originator: originator,
      target: target,
      changes: %{
        "name" => target.name,
        "account_uuid" => target.account.uuid,
        "description" => target.description,
        "id" => target.id,
        "subunit_to_unit" => target.subunit_to_unit,
        "symbol" => target.symbol,
        "blockchain_address" => target.blockchain_address,
        "blockchain_identifier" => target.blockchain_identifier,
        "blockchain_status" => target.blockchain_status,
        "contract_uuid" => target.contract_uuid,
        "blockchain_transaction_uuid" => target.blockchain_transaction_uuid,
        "locked" => target.locked
      },
      encrypted_changes: %{}
    )
  end
end
