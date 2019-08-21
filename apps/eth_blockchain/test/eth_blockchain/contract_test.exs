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

defmodule EthBlockchain.ContractTest do
  use EthBlockchain.EthBlockchainCase, async: true

  alias EthBlockchain.{ABIEncoder, Contract}
  alias Utils.Helpers.Encoding
  alias Keychain.Wallet

  setup state do
    {:ok, {address, _public_key}} = Wallet.generate()

    Map.put(state, :valid_sender, address)
  end

  describe "deploy_erc20/3" do
    test "deploys a non mintable contract successfuly when given locked `true`", state do
      expected_contract_uuid = "3681491a-e8d0-4219-a40a-53d9a47fe64a"
      expected_contract_binary = Contract.get_binary(expected_contract_uuid)
      expected_contract_attributes = ABIEncoder.encode_erc20_attrs("OMGToken", "OMG", 18, 100)
      expected_contract_data = "0x" <> expected_contract_binary <> expected_contract_attributes

      {resp, encoded_trx, contract_address, contract_uuid} =
        Contract.deploy_erc20(
          %{
            from: state[:valid_sender],
            name: "OMGToken",
            symbol: "OMG",
            decimals: 18,
            initial_amount: 100,
            locked: true
          },
          eth_node_adapter: :dumb,
          eth_node_adapter_pid: state[:pid]
        )

      trx = decode_transaction_response(encoded_trx)

      assert trx.init == Encoding.from_hex(expected_contract_data)
      assert contract_uuid == expected_contract_uuid
      assert contract_address != nil

      assert resp == :ok
    end

    test "deploys a mintable contract successfuly when given locked `true`", state do
      expected_contract_uuid = "9e0340c0-9aa4-4a01-b280-d400bc2dca73"
      expected_contract_binary = Contract.get_binary(expected_contract_uuid)
      expected_contract_attributes = ABIEncoder.encode_erc20_attrs("OMGToken", "OMG", 18, 100)
      expected_contract_data = "0x" <> expected_contract_binary <> expected_contract_attributes

      {resp, encoded_trx, contract_address, contract_uuid} =
        Contract.deploy_erc20(
          %{
            from: state[:valid_sender],
            name: "OMGToken",
            symbol: "OMG",
            decimals: 18,
            initial_amount: 100,
            locked: false
          },
          eth_node_adapter: :dumb,
          eth_node_adapter_pid: state[:pid]
        )

      trx = decode_transaction_response(encoded_trx)

      assert trx.init == Encoding.from_hex(expected_contract_data)
      assert contract_uuid == expected_contract_uuid
      assert contract_address != nil

      assert resp == :ok
    end
  end
end
