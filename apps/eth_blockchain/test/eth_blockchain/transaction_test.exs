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

defmodule EthBlockchain.TransactionTest do
  use EthBlockchain.EthBlockchainCase, async: true

  alias EthBlockchain.{Transaction, ABIEncoder}
  alias Keychain.{Signature, Wallet}
  alias Utils.Helpers.Encoding

  setup state do
    {:ok, {address, public_key}} = Wallet.generate()

    state
    |> Map.put(:valid_sender, address)
    |> Map.put(:public_key, public_key)
  end

  defp decode_response(response) do
    response
    |> Encoding.from_hex()
    |> ExRLP.decode()
    |> Transaction.deserialize()
  end

  defp recover_public_key(trx) do
    chain_id = Application.get_env(:eth_blockchain, :chain_id)

    {:ok, pub_key} =
      trx
      |> Transaction.transaction_hash(chain_id)
      |> Signature.recover_public_key(trx.r, trx.s, trx.v, chain_id)

    pub_key
  end

  describe "send/3" do
    test "generates an eth transaction when not specifying contract or gas price", state do
      {resp, encoded_trx} =
        Transaction.send(
          %{from: state[:valid_sender], to: state[:addr_1], amount: 100},
          :dumb,
          state[:pid]
        )

      assert resp == :ok

      trx = decode_response(encoded_trx)
      sender_public_key = recover_public_key(trx)

      assert trx.data == ""
      assert Encoding.to_hex(sender_public_key) == "0x" <> state[:public_key]

      assert trx.gas_limit ==
               Application.get_env(:eth_blockchain, :default_eth_transaction_gas_limit)

      assert trx.gas_price == Application.get_env(:eth_blockchain, :default_gas_price)
      assert trx.value == 100
      assert Encoding.to_hex(trx.to) == state[:addr_1]
    end

    test "generates an eth transaction when not specifying contract", state do
      {resp, encoded_trx} =
        Transaction.send(
          %{from: state[:valid_sender], to: state[:addr_1], amount: 100, gas_price: 50_000},
          :dumb,
          state[:pid]
        )

      assert resp == :ok

      trx = decode_response(encoded_trx)
      sender_public_key = recover_public_key(trx)

      assert trx.data == ""
      assert Encoding.to_hex(sender_public_key) == "0x" <> state[:public_key]

      assert trx.gas_limit ==
               Application.get_env(:eth_blockchain, :default_eth_transaction_gas_limit)

      assert trx.gas_price == 50_000
      assert trx.value == 100
      assert Encoding.to_hex(trx.to) == state[:addr_1]
    end

    test "generates a token transaction when specifying contract", state do
      {resp, encoded_trx} =
        Transaction.send(
          %{
            from: state[:valid_sender],
            to: state[:addr_1],
            amount: 100,
            contract_address: state[:addr_2]
          },
          :dumb,
          state[:pid]
        )

      assert resp == :ok

      trx = decode_response(encoded_trx)
      sender_public_key = recover_public_key(trx)
      {:ok, data} = ABIEncoder.transfer(state[:addr_1], 100)

      assert Encoding.to_hex(sender_public_key) == "0x" <> state[:public_key]

      assert trx.gas_limit ==
               Application.get_env(:eth_blockchain, :default_contract_transaction_gas_limit)

      assert trx.gas_price == Application.get_env(:eth_blockchain, :default_gas_price)
      assert trx.value == 0
      assert Encoding.to_hex(trx.to) == state[:addr_2]
      assert trx.data == data
    end

    test "generates a token transaction when specifying contract and gas price", state do
      {resp, encoded_trx} =
        Transaction.send(
          %{
            from: state[:valid_sender],
            to: state[:addr_1],
            amount: 100,
            contract_address: state[:addr_2],
            gas_price: 50_000
          },
          :dumb,
          state[:pid]
        )

      assert resp == :ok

      trx = decode_response(encoded_trx)
      sender_public_key = recover_public_key(trx)
      {:ok, data} = ABIEncoder.transfer(state[:addr_1], 100)

      assert Encoding.to_hex(sender_public_key) == "0x" <> state[:public_key]

      assert trx.gas_limit ==
               Application.get_env(:eth_blockchain, :default_contract_transaction_gas_limit)

      assert trx.gas_price == 50_000
      assert trx.value == 0
      assert Encoding.to_hex(trx.to) == state[:addr_2]
      assert trx.data == data
    end

    test "returns an error if no such adapter is registered", state do
      assert {:error, :no_handler} ==
               Transaction.send(
                 %{from: state[:valid_sender], to: state[:addr_1], amount: 100},
                 :blah,
                 state[:pid]
               )
    end
  end
end
