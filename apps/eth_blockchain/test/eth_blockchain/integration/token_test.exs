# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EthBlockchain.Integration.TokenTest do
  use ExUnitFixtures
  use EthBlockchain.EthBlockchainIntegrationCase

  alias EthBlockchain.Token
  alias Utils.Helpers.Crypto

  @moduletag :integration

  describe "get_field/3" do
    @tag fixtures: [:omg_contract]
    test "returns the value of the field", %{omg_contract: contract_address} do
      {:ok, name} = Token.get_field(%{field: "name", contract_address: contract_address})
      {:ok, symbol} = Token.get_field(%{field: "symbol", contract_address: contract_address})
      {:ok, decimals} = Token.get_field(%{field: "decimals", contract_address: contract_address})
      {:ok, supply} = Token.get_field(%{field: "totalSupply", contract_address: contract_address})

      assert name == "OMGToken"
      assert symbol == "OMG"
      assert decimals == 18
      assert supply == 100_000_000_000_000_000_000
    end

    @tag fixtures: [:prepare_env]
    test "returns an error when the field is not found in the token" do
      fake_address = Crypto.fake_eth_address()
      {res, value} = Token.get_field(%{field: "name", contract_address: fake_address})
      assert res == :error
      assert value == :field_not_found
    end
  end
end
