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
    overwritten_opts = Keyword.merge(state[:adapter_opts], eth_node_adapter: :dumb_tx)

    state
    |> Map.put(:valid_sender, address)
    |> Map.put(:adapter_opts, overwritten_opts)
  end

  describe "deploy_erc20/3" do
    test "deploys a non mintable contract successfuly when given locked `true`", state do
      expected_contract_uuid = Contract.locked_contract_uuid()
      expected_contract_binary = Contract.get_binary(expected_contract_uuid)
      expected_contract_attributes = ABIEncoder.encode_erc20_attrs("OMGToken", "OMG", 18, 100)
      expected_contract_data = "0x" <> expected_contract_binary <> expected_contract_attributes

      {resp, %{contract_address: contract_address, contract_uuid: contract_uuid} = tx_response} =
        Contract.deploy_erc20(
          %{
            from: state[:valid_sender],
            name: "OMGToken",
            symbol: "OMG",
            decimals: 18,
            initial_amount: 100,
            locked: true
          },
          state[:adapter_opts]
        )

      trx = decode_transaction_response(tx_response)

      assert trx.init == Encoding.from_hex(expected_contract_data)
      assert contract_uuid == expected_contract_uuid
      assert contract_address != nil

      assert resp == :ok
    end

    test "deploys a mintable contract successfuly when given locked `true`", state do
      expected_contract_uuid = Contract.unlocked_contract_uuid()
      expected_contract_binary = Contract.get_binary(expected_contract_uuid)
      expected_contract_attributes = ABIEncoder.encode_erc20_attrs("OMGToken", "OMG", 18, 100)
      expected_contract_data = "0x" <> expected_contract_binary <> expected_contract_attributes

      {resp, %{contract_address: contract_address, contract_uuid: contract_uuid} = tx_response} =
        Contract.deploy_erc20(
          %{
            from: state[:valid_sender],
            name: "OMGToken",
            symbol: "OMG",
            decimals: 18,
            initial_amount: 100,
            locked: false
          },
          state[:adapter_opts]
        )

      trx = decode_transaction_response(tx_response)

      assert trx.init == Encoding.from_hex(expected_contract_data)
      assert contract_uuid == expected_contract_uuid
      assert contract_address != nil

      assert resp == :ok
    end
  end
end
