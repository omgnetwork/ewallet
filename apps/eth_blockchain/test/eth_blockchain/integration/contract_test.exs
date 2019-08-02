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

defmodule EthBlockchain.Integration.ContractTest do
  use ExUnitFixtures
  use EthBlockchain.EthBlockchainIntegrationCase

  alias EthBlockchain.{WaitFor, Contract}

  @moduletag :integration

  describe "deploy_erc20/3" do
    @tag fixtures: [:funded_hot_wallet]
    test "deploys a locked ERC20 token successfuly", %{funded_hot_wallet: hot_wallet} do
      {res, tx_hash, contract_address, contract_uuid} =
        Contract.deploy_erc20(%{
          locked: true,
          from: hot_wallet.address,
          name: "OMGToken",
          symbol: "OMG",
          decimals: 18,
          initial_amount: 100_000
        })

      assert res == :ok
      assert tx_hash != nil
      assert contract_address != nil
      assert contract_uuid == "3681491a-e8d0-4219-a40a-53d9a47fe64a"


      {res, tx} = WaitFor.eth_receipt(tx_hash)
      assert res == :ok
      assert tx["status"] == "0x1"
      assert tx["contractAddress"] == contract_address
    end

    @tag fixtures: [:funded_hot_wallet]
    test "deploys an unlocked ERC20 token successfuly", %{funded_hot_wallet: hot_wallet} do
      {res, tx_hash, contract_address, contract_uuid} =
        Contract.deploy_erc20(%{
          locked: false,
          from: hot_wallet.address,
          name: "OMGToken",
          symbol: "OMG",
          decimals: 18,
          initial_amount: 100_000
        })

      assert res == :ok
      assert tx_hash != nil
      assert contract_address != nil
      assert contract_uuid == "9e0340c0-9aa4-4a01-b280-d400bc2dca73"


      {res, tx} = WaitFor.eth_receipt(tx_hash)
      assert res == :ok
      assert tx["status"] == "0x1"
      assert tx["contractAddress"] == contract_address
    end
  end
end
