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

defmodule EthBlockchain.TokenTest do
  use EthBlockchain.EthBlockchainCase, async: true

  alias EthBlockchain.Token
  alias Utils.Helpers.Crypto

  describe "get_field/2" do
    test "get a valid field with the given adapter spec", state do
      resp =
        Token.get_field(
          %{
            field: "name",
            contract_address: Crypto.fake_eth_address()
          },
          state[:adapter_opts]
        )

      assert resp == {:ok, "OMGToken"}
    end

    test "fails to get an invalid field", state do
      resp =
        Token.get_field(
          %{
            field: "invalid field",
            contract_address: Crypto.fake_eth_address()
          },
          state[:adapter_opts]
        )

      assert resp == {:error, :invalid_field}
    end

    test "fails to get a valid field for an invalid contract address", state do
      resp =
        Token.get_field(
          %{
            field: "name",
            contract_address: DumbAdapter.invalid_erc20_contract_address()
          },
          state[:adapter_opts]
        )

      assert resp == {:error, :field_not_found}
    end

    test "returns an error if no such adapter is registered", state do
      assert {:error, :no_handler} ==
               Token.get_field(
                 %{
                   field: "name",
                   contract_address: Crypto.fake_eth_address()
                 },
                 state[:invalid_adapter_opts]
               )
    end
  end

  describe "locked?/2" do
    test "returns a boolean indicating if the minting is still possible or not", state do
      resp = Token.locked?(%{contract_address: Crypto.fake_eth_address()}, state[:adapter_opts])

      assert resp == {:ok, true}
    end
  end
end
