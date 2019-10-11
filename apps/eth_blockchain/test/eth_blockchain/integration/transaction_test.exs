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

defmodule EthBlockchain.Integration.TransactionTest do
  use ExUnitFixtures
  use EthBlockchain.EthBlockchainIntegrationCase

  alias EthBlockchain.{ABIEncoder, Contract, IntegrationHelpers, Transaction}

  @moduletag :integration

  describe "send/3" do
    @tag fixtures: [:funded_hot_wallet, :alice]
    test "send ethereum successfuly", %{funded_hot_wallet: hot_wallet, alice: alice} do
      {res, %{tx_hash: tx_hash, gas_price: gas_price, gas_limit: gas_limit}} =
        Transaction.send(%{
          contract_address: "0x0000000000000000000000000000000000000000",
          from: hot_wallet.address,
          to: alice.address,
          amount: 100
        })

      assert res == :ok
      assert tx_hash != nil
      assert gas_price != nil
      assert gas_limit != nil

      {sync_res, tx} = IntegrationHelpers.transact_sync!({res, tx_hash})

      assert sync_res == :ok

      assert tx["from"] == hot_wallet.address
      assert tx["to"] == alice.address
      assert tx["transactionHash"] == tx_hash
      assert tx["status"] == "0x1"
    end

    @tag fixtures: [:funded_hot_wallet, :omg_contract, :alice]
    test "send erc20 successfuly", %{
      funded_hot_wallet: hot_wallet,
      omg_contract: contract_address,
      alice: alice
    } do
      {res, %{tx_hash: tx_hash, gas_price: gas_price, gas_limit: gas_limit}} =
        Transaction.send(%{
          contract_address: contract_address,
          from: hot_wallet.address,
          to: alice.address,
          amount: 100
        })

      assert res == :ok
      assert tx_hash != nil
      assert gas_price != nil
      assert gas_limit != nil

      {sync_res, tx} = IntegrationHelpers.transact_sync!({res, tx_hash})

      assert sync_res == :ok
      assert tx["from"] == hot_wallet.address
      assert tx["to"] == contract_address
      assert tx["transactionHash"] == tx_hash
      assert tx["status"] == "0x1"
    end
  end

  describe "create_contract/3" do
    @tag fixtures: [:funded_hot_wallet]
    test "create an erc20 token successfuly", %{funded_hot_wallet: hot_wallet} do
      name = "OMGToken"
      symbol = "OMG"
      decimals = 18
      initial_amount = 100_000

      data =
        "0x" <>
          Contract.get_binary(Contract.locked_contract_uuid()) <>
          ABIEncoder.encode_erc20_attrs(name, symbol, decimals, initial_amount)

      {res, %{tx_hash: tx_hash, contract_address: contract_address}} =
        Transaction.create_contract(%{
          from: hot_wallet.address,
          contract_data: data
        })

      assert res == :ok
      assert tx_hash != nil
      assert contract_address != nil

      {sync_res, tx} = IntegrationHelpers.transact_sync!({res, tx_hash})

      assert sync_res == :ok
      assert tx["from"] == hot_wallet.address
      assert tx["to"] == nil
      assert tx["contractAddress"] == contract_address
      assert tx["transactionHash"] == tx_hash
      assert tx["status"] == "0x1"
    end
  end
end
