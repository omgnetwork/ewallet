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

defmodule EWallet.TokenGateTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.{TokenGate, BlockchainHelper}
  alias EWalletDB.Token
  alias Utils.Helpers.Crypto

  describe "deploy_erc20" do
    test "successfuly deploy a locked erc20 contract with the given attributes" do
      name = "OMGToken"
      symbol = "OMG"
      subunit_to_unit = 100
      amount = 1000
      locked = true

      {res, attrs} =
        TokenGate.deploy_erc20(%{
          "name" => name,
          "symbol" => symbol,
          "subunit_to_unit" => subunit_to_unit,
          "amount" => amount,
          "locked" => locked
        })

      assert res == :ok
      assert attrs["blockchain_address"] != nil
      assert attrs["blockchain_identifier"] == BlockchainHelper.rootchain_identifier()
      assert attrs["blockchain_status"] == "pending"
      assert attrs["contract_uuid"] == "3681491a-e8d0-4219-a40a-53d9a47fe64a"
      assert attrs["tx_hash"] != nil
    end

    test "successfuly deploy an unlocked erc20 contract with the given attributes" do
      name = "OMGToken"
      symbol = "OMG"
      subunit_to_unit = 100
      amount = 1000
      locked = false

      {res, attrs} =
        TokenGate.deploy_erc20(%{
          "name" => name,
          "symbol" => symbol,
          "subunit_to_unit" => subunit_to_unit,
          "amount" => amount,
          "locked" => locked
        })

      assert res == :ok
      assert attrs["blockchain_address"] != nil
      assert attrs["blockchain_identifier"] == BlockchainHelper.rootchain_identifier()
      assert attrs["blockchain_status"] == "pending"
      assert attrs["contract_uuid"] == "9e0340c0-9aa4-4a01-b280-d400bc2dca73"
      assert attrs["tx_hash"] != nil
    end

    test "returns an `invalid_parameter` error if name is missing" do
      symbol = "OMG"
      subunit_to_unit = 100
      amount = 1000
      locked = false

      {res, code, _message} =
        TokenGate.deploy_erc20(%{
          "symbol" => symbol,
          "subunit_to_unit" => subunit_to_unit,
          "amount" => amount,
          "locked" => locked
        })

      assert res == :error
      assert code == :invalid_parameter
    end

    test "returns an `invalid_parameter` error if symbol is missing" do
      name = "OMGToken"
      subunit_to_unit = 100
      amount = 1000
      locked = false

      {res, code, _message} =
        TokenGate.deploy_erc20(%{
          "name" => name,
          "subunit_to_unit" => subunit_to_unit,
          "amount" => amount,
          "locked" => locked
        })

      assert res == :error
      assert code == :invalid_parameter
    end

    test "returns an `invalid_parameter` error if subunit_to_unit is missing" do
      name = "OMGToken"
      symbol = "OMG"
      amount = 1000
      locked = false

      {res, code, _message} =
        TokenGate.deploy_erc20(%{
          "name" => name,
          "symbol" => symbol,
          "amount" => amount,
          "locked" => locked
        })

      assert res == :error
      assert code == :invalid_parameter
    end

    test "returns an `invalid_parameter` error if locked is missing" do
      name = "OMGToken"
      symbol = "OMG"
      amount = 1000
      subunit_to_unit = 100

      {res, code, _message} =
        TokenGate.deploy_erc20(%{
          "name" => name,
          "symbol" => symbol,
          "amount" => amount,
          "subunit_to_unit" => subunit_to_unit
        })

      assert res == :error
      assert code == :invalid_parameter
    end

    test "returns an `invalid_parameter` error if amount is missing" do
      name = "OMGToken"
      symbol = "OMG"
      locked = false
      subunit_to_unit = 100

      {res, code, _message} =
        TokenGate.deploy_erc20(%{
          "name" => name,
          "symbol" => symbol,
          "locked" => locked,
          "subunit_to_unit" => subunit_to_unit
        })

      assert res == :error
      assert code == :invalid_parameter
    end
  end

  describe "get_erc20_capabilities/1" do
    test "successfuly get erc20 attributes for a valid contract address" do
      address = Crypto.fake_eth_address()
      {res, attrs} = TokenGate.get_erc20_capabilities(address)

      assert res == :ok
      assert attrs.decimals == 18
      assert attrs.hot_wallet_balance == 123
      assert attrs.name == "OMGToken"
      assert attrs.symbol == "OMG"
      assert attrs.total_supply == 100_000_000_000_000_000_000
    end

    test "returns an `token_not_erc20` error for an invalid contract address" do
      invalid_address = BlockchainHelper.invalid_erc20_contract_address()
      {res, error} = TokenGate.get_erc20_capabilities(invalid_address)

      assert res == :error
      assert error == :token_not_erc20
    end
  end

  describe "validate_erc20_readiness/2" do
    test "successfuly validate a valid token" do
      token = insert(:token, %{symbol: "OMG", subunit_to_unit: 1_000_000_000_000_000_000})
      address = Crypto.fake_eth_address()

      {res, status} = TokenGate.validate_erc20_readiness(address, token)

      assert res == :ok
      # status is confirmed because the dumb adapter returns a positive balance (123)
      assert status == Token.blockchain_status_confirmed()
    end

    test "returns an error when the token decimals doesn't match" do
      token = insert(:token, %{symbol: "OMG", subunit_to_unit: 1})
      address = Crypto.fake_eth_address()
      {res, status} = TokenGate.validate_erc20_readiness(address, token)

      assert res == :error
      assert status == :token_not_matching_contract_info
    end

    test "returns an error when the token symbol doesn't match" do
      token = insert(:token, %{symbol: "BTC", subunit_to_unit: 1_000_000_000_000_000_000})
      address = Crypto.fake_eth_address()
      {res, status} = TokenGate.validate_erc20_readiness(address, token)

      assert res == :error
      assert status == :token_not_matching_contract_info
    end

    test "returns an error when the token is not a valid erc20" do
      token = insert(:token, %{symbol: "OMG", subunit_to_unit: 1_000_000_000_000_000_000})
      invalid_address = BlockchainHelper.invalid_erc20_contract_address()

      {res, status} = TokenGate.validate_erc20_readiness(invalid_address, token)

      assert res == :error
      assert status == :token_not_erc20
    end
  end

  describe "get_blockchain_status/1" do
    test "returns a pending status when balance is 0" do
      status = TokenGate.get_blockchain_status(%{hot_wallet_balance: 0})
      assert status == Token.blockchain_status_pending()
    end

    test "returns a confirmed status when balance is > 0" do
      status = TokenGate.get_blockchain_status(%{hot_wallet_balance: 1})
      assert status == Token.blockchain_status_confirmed()
    end
  end
end
