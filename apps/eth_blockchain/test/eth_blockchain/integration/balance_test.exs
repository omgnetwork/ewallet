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

defmodule EthBlockchain.Integration.BalanceTest do
  use ExUnitFixtures
  use EthBlockchain.EthBlockchainIntegrationCase

  alias EthBlockchain.{Balance, Helper, IntegrationHelpers}

  @moduletag :integration

  describe "get/1" do
    @tag fixtures: [:hot_wallet, :omg_contract, :alice]
    test "successfuly get wallet balances for an address", %{
      alice: alice,
      hot_wallet: hot_wallet,
      omg_contract: contract_address
    } do
      {:ok, _} = IntegrationHelpers.fund_account(alice.address, 100_000)

      :ok =
        IntegrationHelpers.transfer_erc20(%{
          from: hot_wallet.address,
          to: alice.address,
          amount: 50_000,
          contract_address: contract_address
        })

      resp =
        Balance.get(
          %{
            address: alice.address,
            contract_addresses: [Helper.default_address(), contract_address]
          }
        )

      assert resp == {:ok, %{Helper.default_address() => 100_000, contract_address => 50_000}}
    end
  end
end
