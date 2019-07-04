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
  alias EWallet.TokenGate
  alias EWalletDB.Token

  defp valid_erc20_contract_address do
    Application.get_env(:ewallet, :blockchain_adapter).dumb_adapter.valid_erc20_contract_address()
  end

  defp invalid_erc20_contract_address do
    Application.get_env(:ewallet, :blockchain_adapter).dumb_adapter.invalid_erc20_contract_address()
  end

  describe "get_erc20_capabilities/1" do
    test "successfuly get erc20 attributes for a valid contract address" do
      {res, attrs} = TokenGate.get_erc20_capabilities(valid_erc20_contract_address())

      assert res == :ok
      assert attrs.decimals == 18
      assert attrs.hot_wallet_balance == 123
      assert attrs.name == "OMGToken"
      assert attrs.symbol == "OMG"
      assert attrs.total_supply == 100_000_000_000_000_000_000
    end

    test "returns an `token_not_erc20` error for an invalid contract address" do
      {res, error} = TokenGate.get_erc20_capabilities(invalid_erc20_contract_address())

      assert res == :error
      assert error == :token_not_erc20
    end
  end

  describe "validate_erc20_readiness/2" do
    test "successfuly validate a valid token" do
      token = insert(:token, %{symbol: "OMG", subunit_to_unit: 1_000_000_000_000_000_000})

      {res, status} = TokenGate.validate_erc20_readiness(valid_erc20_contract_address(), token)

      assert res == :ok
      # status is confirmed because the dumb adapter returns a positive balance (123)
      assert status == Token.blockchain_status_confirmed()
    end

    test "returns an error when the token decimals doesn't match" do
      token = insert(:token, %{symbol: "OMG", subunit_to_unit: 1})

      {res, status} = TokenGate.validate_erc20_readiness(valid_erc20_contract_address(), token)

      assert res == :error
      assert status == :token_not_matching_contract_info
    end

    test "returns an error when the token symbol doesn't match" do
      token = insert(:token, %{symbol: "BTC", subunit_to_unit: 1_000_000_000_000_000_000})

      {res, status} = TokenGate.validate_erc20_readiness(valid_erc20_contract_address(), token)

      assert res == :error
      assert status == :token_not_matching_contract_info
    end

    test "returns an error when the token is not a valid erc20" do
      token = insert(:token, %{symbol: "OMG", subunit_to_unit: 1_000_000_000_000_000_000})

      {res, status} = TokenGate.validate_erc20_readiness(invalid_erc20_contract_address(), token)

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
