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
  alias Utils.Helpers.{Crypto, Encoding}
  alias Keychain.Wallet
  alias ABI.{TypeEncoder, FunctionSelector}

  setup state do
    {:ok, {address, _public_key}} = Wallet.generate()

    Map.put(state, :valid_sender, address)
  end

  describe "deploy_erc20/3" do
    test "deploys a non mintable contract successfuly when given locked `true`", state do
      expected_contract_uuid = "3681491a-e8d0-4219-a40a-53d9a47fe64a"

      expected_contract_binary =
        :eth_blockchain
        |> Application.app_dir()
        |> Path.join("priv/contracts.json")
        |> File.read!()
        |> Jason.decode!()
        |> Map.get(expected_contract_uuid)
        |> Map.get("binary")

      expected_contract_attributes =
        [{"OMGToken", "OMG", 18, 100}]
        |> TypeEncoder.encode(%FunctionSelector{
          function: nil,
          types: [{:tuple, [:string, :string, {:uint, 8}, {:uint, 256}]}]
        })
        |> Base.encode16(case: :lower)

      expected_contract_data = "0x" <> expected_contract_binary <> expected_contract_attributes

      {resp, encoded_trx, contract_address, contract_uuid} =
        Token.deploy_erc20(
          %{
            from: state[:valid_sender],
            name: "OMGToken",
            symbol: "OMG",
            decimals: 18,
            initial_amount: 100,
            locked: true
          },
          :dumb,
          state[:pid]
        )

      trx = decode_transaction_response(encoded_trx)

      assert trx.init == Encoding.from_hex(expected_contract_data)
      assert contract_uuid == expected_contract_uuid
      assert contract_address != nil

      assert resp == :ok
    end

    test "deploys a mintable contract successfuly when given locked `true`", state do
      expected_contract_uuid = "9e0340c0-9aa4-4a01-b280-d400bc2dca73"

      expected_contract_binary =
        :eth_blockchain
        |> Application.app_dir()
        |> Path.join("priv/contracts.json")
        |> File.read!()
        |> Jason.decode!()
        |> Map.get(expected_contract_uuid)
        |> Map.get("binary")

      expected_contract_attributes =
        [{"OMGToken", "OMG", 18, 100}]
        |> TypeEncoder.encode(%FunctionSelector{
          function: nil,
          types: [{:tuple, [:string, :string, {:uint, 8}, {:uint, 256}]}]
        })
        |> Base.encode16(case: :lower)

      expected_contract_data = "0x" <> expected_contract_binary <> expected_contract_attributes

      {resp, encoded_trx, contract_address, contract_uuid} =
        Token.deploy_erc20(
          %{
            from: state[:valid_sender],
            name: "OMGToken",
            symbol: "OMG",
            decimals: 18,
            initial_amount: 100,
            locked: false
          },
          :dumb,
          state[:pid]
        )

      trx = decode_transaction_response(encoded_trx)

      assert trx.init == Encoding.from_hex(expected_contract_data)
      assert contract_uuid == expected_contract_uuid
      assert contract_address != nil

      assert resp == :ok
    end
  end

  describe "get_field/3" do
    test "get a valid field with the given adapter spec", state do
      resp =
        Token.get_field(
          %{
            field: "name",
            contract_address: Crypto.fake_eth_address()
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
            contract_address: Crypto.fake_eth_address()
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
                   contract_address: Crypto.fake_eth_address()
                 },
                 :blah,
                 state[:pid]
               )
    end
  end
end
