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

defmodule EthBlockchain.GasHelperTest do
  use EthBlockchain.EthBlockchainCase, async: true

  alias EthBlockchain.GasHelper

  describe "get_gas_limit_or_default/2" do
    test "returns the specified gas limit when present" do
      gas_limit = GasHelper.get_gas_limit_or_default(:eth_transaction, %{gas_limit: 1337})

      assert gas_limit == 1337
    end

    test "returns the default gas limit for the specified type if not present" do
      gas_limit = GasHelper.get_gas_limit_or_default(:eth_transaction, %{})

      assert gas_limit ==
               :eth_blockchain
               |> Application.get_env(:gas_limit)
               |> Keyword.get(:eth_transaction)
    end
  end

  describe "get_gas_price_or_default/1" do
    test "returns the specified gas price when present" do
      gas_price = GasHelper.get_gas_price_or_default(%{gas_price: 1337})
      assert gas_price == 1337
    end

    test "returns the default gas price for if not present" do
      gas_price = GasHelper.get_gas_price_or_default(%{})
      assert gas_price == Application.get_env(:eth_blockchain, :default_gas_price)
    end
  end
end
