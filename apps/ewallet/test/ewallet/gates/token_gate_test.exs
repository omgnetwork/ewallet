# Copyright 2017-2019 OmiseGO Pte Ltd
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

defmodule EWallet.TokenGateTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias ActivityLogger.System
  alias EWallet.{GethSimulator, TokenGate}
  alias EWalletDB.{Account, Mint, Token}
  alias Utils.Helpers.Unit

  describe "create/1" do
    test "creates the token" do
      attrs = %{
        "symbol" => "OMG",
        "name" => "OmiseGO",
        "subunit_to_unit" => 1_000_000_000_000_000_000,
        "originator" => %System{}
      }

      {res, mint, token} = TokenGate.create(attrs)

      assert res == :ok
      assert mint == nil
      assert %Token{} = token
      assert token.name == attrs["name"]
      assert token.symbol == attrs["symbol"]
      assert token.subunit_to_unit == attrs["subunit_to_unit"]
    end

    test "associates the created token with the local ledger and master account" do
      attrs = %{
        "symbol" => "OMG",
        "name" => "OmiseGO",
        "subunit_to_unit" => 1_000_000_000_000_000_000,
        "originator" => %System{}
      }

      {:ok, _, token} = TokenGate.create(attrs)

      assert token.ledger == LocalLedgerDB.identifier()
      assert token.account_uuid == Account.get_master_account().uuid
    end

    test "mints the token if amount is given" do
      attrs = %{
        "symbol" => "OMG",
        "name" => "OmiseGO",
        "amount" => 1_000_000_000,
        "subunit_to_unit" => 1_000_000_000_000_000_000,
        "originator" => %System{}
      }

      {:ok, mint, token} = TokenGate.create(attrs)

      assert %Mint{} = mint
      assert mint.token_uuid == token.uuid
      assert mint.amount == attrs["amount"]
    end

    test "mints the token if amount is given as string" do
      amount = 1_000_000_000

      attrs = %{
        "symbol" => "OMG",
        "name" => "OmiseGO",
        "amount" => to_string(amount),
        "subunit_to_unit" => 1_000_000_000_000_000_000,
        "originator" => %System{}
      }

      {:ok, mint, token} = TokenGate.create(attrs)

      assert %Mint{} = mint
      assert mint.token_uuid == token.uuid
      assert mint.amount == amount
    end

    test "returns error if the mint amount is invalid" do
      attrs = %{
        "symbol" => "OMG",
        "name" => "OmiseGO",
        "amount" => "1 million",
        "subunit_to_unit" => 1_000_000_000_000_000_000,
        "originator" => %System{}
      }

      {res, error, description} = TokenGate.create(attrs)

      assert res == :error
      assert error == :invalid_parameter

      assert description ==
               "Invalid parameter provided. String number is not a valid number: '#{
                 attrs["amount"]
               }'."
    end

    test "returns error if the mint amount is zero" do
      attrs = %{
        "symbol" => "OMG",
        "name" => "OmiseGO",
        "amount" => 0,
        "subunit_to_unit" => 1_000_000_000_000_000_000,
        "originator" => %System{}
      }

      {res, error, description} = TokenGate.create(attrs)

      assert res == :error
      assert error == :invalid_parameter
      assert description == "Invalid amount provided: '#{attrs["amount"]}'."
    end

    test "returns error if the mint amount is less than zero" do
      attrs = %{
        "symbol" => "OMG",
        "name" => "OmiseGO",
        "amount" => -100,
        "subunit_to_unit" => 1_000_000_000_000_000_000,
        "originator" => %System{}
      }

      {res, error, description} = TokenGate.create(attrs)

      assert res == :error
      assert error == :invalid_parameter
      assert description == "Invalid amount provided: '#{attrs["amount"]}'."
    end
  end

  describe "import/1" do
    test "imports the token successfully" do
      _ = GethSimulator.start()

      {res, token} =
        TokenGate.import(%{
          "contract_address" => "0x000",
          "adapter" => "ethereum",
          "originator" => insert(:user),
          "account_uuid" => insert(:account).uuid
        })

      assert res == :ok
      assert %Token{} = token
      assert token.name == GethSimulator.token_data().name
      assert token.symbol == GethSimulator.token_data().symbol

      assert token.subunit_to_unit ==
               Unit.decimals_to_subunit(GethSimulator.token_data().decimals)
    end

    test "imports the token with the overridden data" do
      _ = GethSimulator.start()
      token_data = GethSimulator.token_data()
      name = "Overridden Name"
      symbol = "OVERRIDE"
      decimals = 7

      refute name == token_data.name
      refute symbol == token_data.symbol
      refute decimals == token_data.decimals

      {res, token} =
        TokenGate.import(%{
          "contract_address" => "0x000",
          "adapter" => "ethereum",
          "name" => name,
          "symbol" => symbol,
          "subunit_to_unit" => Unit.decimals_to_subunit(decimals),
          "originator" => insert(:user),
          "account_uuid" => insert(:account).uuid
        })

      assert res == :ok
      assert %Token{} = token
      assert token.name == name
      assert token.symbol == symbol
      assert token.subunit_to_unit == Unit.decimals_to_subunit(decimals)
    end

    test "returns error if the contract address is not provided" do
      _ = GethSimulator.start()
      name = GethSimulator.token_data().name
      _ = insert(:token, name: name)

      {res, code, description} =
        TokenGate.import(%{
          "adapter" => "ethereum",
          "originator" => insert(:user),
          "account_uuid" => insert(:account).uuid
        })

      assert res == :error
      assert code == :token_already_exists
      assert description == "A token with the name '#{name}' already exists."
    end

    test "returns error if the adapter is not provided" do
      _ = GethSimulator.start()
      symbol = GethSimulator.token_data().symbol
      _ = insert(:token, symbol: symbol)

      {res, code, description} =
        TokenGate.import(%{
          "contract_address" => "0x000",
          "originator" => insert(:user),
          "account_uuid" => insert(:account).uuid
        })

      assert res == :error
      assert code == :invalid_parameter

      assert description ==
               "Invalid parameter provided. `adapter` must be one of [\"ethereum\", \"omg_network\"]."
    end

    test "returns error if the adapter is invalid" do
      _ = GethSimulator.start()
      symbol = GethSimulator.token_data().symbol
      _ = insert(:token, symbol: symbol)

      {res, code, description} =
        TokenGate.import(%{
          "contract_address" => "0x000",
          "adapter" => "not_valid_adapter",
          "originator" => insert(:user),
          "account_uuid" => insert(:account).uuid
        })

      assert res == :error
      assert code == :invalid_parameter

      assert description ==
               "Invalid parameter provided. `adapter` must be one of [\"ethereum\", \"omg_network\"]."
    end

    test "returns error if the token name already exists" do
      _ = GethSimulator.start()
      name = GethSimulator.token_data().name
      _ = insert(:token, name: name)

      {res, code, description} =
        TokenGate.import(%{
          "contract_address" => "0x000",
          "adapter" => "ethereum",
          "originator" => insert(:user),
          "account_uuid" => insert(:account).uuid
        })

      assert res == :error
      assert code == :token_already_exists
      assert description == "A token with the name '#{name}' already exists."
    end

    test "returns error if the token symbol already exists" do
      _ = GethSimulator.start()
      symbol = GethSimulator.token_data().symbol
      _ = insert(:token, symbol: symbol)

      {res, code, description} =
        TokenGate.import(%{
          "contract_address" => "0x000",
          "adapter" => "ethereum",
          "originator" => insert(:user),
          "account_uuid" => insert(:account).uuid
        })

      assert res == :error
      assert code == :token_already_exists
      assert description == "A token with the symbol '#{symbol}' already exists."
    end

    test "returns error if the token contract address already exists" do
      _ = GethSimulator.start()
      address = "0x123456789"

      # We don't have a direct access to the ledger so we do double imports instead.
      {:ok, _} =
        TokenGate.import(%{
          "contract_address" => address,
          "adapter" => "ethereum",
          "originator" => insert(:user),
          "account_uuid" => insert(:account).uuid
        })

      {res, code, description} =
        TokenGate.import(%{
          "contract_address" => address,
          "adapter" => "ethereum",
          "name" => "Some Other Token Name",
          "symbol" => "ABCD",
          "originator" => insert(:user),
          "account_uuid" => insert(:account).uuid
        })

      assert res == :error
      assert code == :token_already_exists
      assert description == "A token with the contract address '#{address}' already exists."
    end
  end
end
