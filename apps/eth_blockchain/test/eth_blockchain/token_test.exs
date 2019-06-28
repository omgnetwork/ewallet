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

  describe "get_field/3" do
    test "get a valid field with the given adapter spec", state do
      resp =
        Token.get_field(
          %{
            field: "name",
            contract_address: DumbAdapter.valid_erc20_contract_address()
          },
          :dumb,
          state[:pid]
        )

      assert resp == {:ok, "OMGToken"}
    end

    test "fails to get an invalid field", state do
      resp =
        Token.get_field(
          %{
            field: "invalid field",
            contract_address: DumbAdapter.valid_erc20_contract_address()
          },
          :dumb,
          state[:pid]
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
          :dumb,
          state[:pid]
        )

      assert resp == {:error, :field_not_found}
    end

    test "returns an error if no such adapter is registered", state do
      assert {:error, :no_handler} ==
               Token.get_field(
                 %{
                   field: "name",
                   contract_address: DumbAdapter.valid_erc20_contract_address()
                 },
                 :blah,
                 state[:pid]
               )
    end
  end
end
