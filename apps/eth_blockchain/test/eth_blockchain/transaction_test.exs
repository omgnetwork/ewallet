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

  alias EthBlockchain.{GasHelper, Transaction, ABIEncoder}
  alias ExthCrypto.Math
  alias Keychain.Wallet
  alias Utils.Helpers.Encoding

  setup state do
    {:ok, {address, public_key}} = Wallet.generate()
    overwritten_opts = Keyword.merge(state[:adapter_opts], [eth_node_adapter: :dumb_tx])

    state
    |> Map.put(:valid_sender, address)
    |> Map.put(:public_key, public_key)
    |> Map.put(:adapter_opts, overwritten_opts)
  end

  describe "create_contract/3" do
    test "generates a contract creation transaction", state do
      contract_data = "0x" <> "0123456789abcdef"

      {resp, encoded_trx, contract_address} =
        Transaction.create_contract(
          %{from: state[:valid_sender], contract_data: contract_data},
          state[:adapter_opts]
        )

      assert resp == :ok

      trx = decode_transaction_response(encoded_trx)

      sender_public_key = recover_public_key(trx)

      assert trx.data == ""
      assert trx.init == Encoding.from_hex(contract_data)
      assert Encoding.to_hex(sender_public_key) == "0x" <> state[:public_key]

      assert trx.gas_limit ==
               Application.get_env(:eth_blockchain, :default_contract_creation_gas_limit)

      assert trx.gas_price == Application.get_env(:eth_blockchain, :default_gas_price)
      assert trx.value == 0
      assert Encoding.to_hex(trx.to) == "0x"

      assert contract_address != nil
    end
  end

  describe "send/3" do
    test "generates an eth transaction when not specifying contract or gas price", state do
      {resp, encoded_trx} =
        Transaction.send(
          %{from: state[:valid_sender], to: state[:addr_1], amount: 100},
          state[:adapter_opts]
        )

      assert resp == :ok

      trx = decode_transaction_response(encoded_trx)
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
          state[:adapter_opts]
        )

      assert resp == :ok

      trx = decode_transaction_response(encoded_trx)
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
          state[:adapter_opts]
        )

      assert resp == :ok

      trx = decode_transaction_response(encoded_trx)
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
          state[:adapter_opts]
        )

      assert resp == :ok

      trx = decode_transaction_response(encoded_trx)
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
                 state[:invalid_adapter_opts]
               )
    end
  end

  describe "transaction_hash/2" do
    test "returns the hash of the given transaction", state do
      {:ok, encoded_trx} =
        Transaction.send(
          %{from: state[:valid_sender], to: state[:addr_1], amount: 100},
          state[:adapter_opts]
        )

      trx = decode_transaction_response(encoded_trx)
      hash_hex = trx |> Transaction.transaction_hash(10) |> Math.bin_to_hex()

      assert hash_hex == "94949cf3c67b0cc3c203ff4b98734f8d466da74d034e2d030dba476622f0f9c1"
    end
  end

  describe "serialize/2" do
    test "returns the RLP-encoded transaction including vrs", state do
      {:ok, encoded_trx} =
        Transaction.send(
          %{from: state[:valid_sender], to: state[:addr_1], amount: 100},
          state[:adapter_opts]
        )

      trx = decode_transaction_response(encoded_trx)
      serialized = Transaction.serialize(trx, true)

      assert [
               "",
               <<4, 168, 23, 200, 0>>,
               "R\b",
               <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
               "d",
               "",
               v,
               r,
               s
             ] = serialized

      # vrs change for every call, so assert only their size
      assert v != nil
      assert byte_size(r) in 31..32
      assert byte_size(s) in 31..32
    end

    test "returns the RLP-encoded transaction excluding vrs", state do
      {:ok, encoded_trx} =
        Transaction.send(
          %{from: state[:valid_sender], to: state[:addr_1], amount: 100},
          state[:adapter_opts]
        )

      trx = decode_transaction_response(encoded_trx)

      assert Transaction.serialize(trx, false) == [
               "",
               <<4, 168, 23, 200, 0>>,
               "R\b",
               <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
               "d",
               ""
             ]
    end
  end

  describe "deposit_eth/2" do
    test "generates a desposit transaction for eth currency", state do
      tx_bytes = "0x01"
      amount = 100
      {resp, encoded_trx} =
        Transaction.deposit_eth(
          %{
            tx_bytes: tx_bytes,
            from: state[:valid_sender],
            amount: amount,
            root_chain_contract: state[:addr_1]
          },
          state[:adapter_opts]
        )

      assert resp == :ok

      {:ok, encoded_abi_data} = ABIEncoder.child_chain_eth_deposit(tx_bytes)

      trx = decode_transaction_response(encoded_trx)
      sender_public_key = recover_public_key(trx)

      assert trx.data == encoded_abi_data
      assert Encoding.to_hex(sender_public_key) == "0x" <> state[:public_key]
      assert trx.gas_limit == GasHelper.get_gas_limit_or_default(:child_chain_deposit_eth, %{})
      assert trx.gas_price == Application.get_env(:eth_blockchain, :default_gas_price)
      assert trx.value == amount
      assert Encoding.to_hex(trx.to) == state[:addr_1]
    end
  end

  describe "deposit_erc20/2" do
    test "generates a desposit transaction for erc20 currency", state do
      tx_bytes = "0x01"
      {resp, encoded_trx} =
        Transaction.deposit_erc20(
          %{
            tx_bytes: tx_bytes,
            from: state[:valid_sender],
            root_chain_contract: state[:addr_1]
          },
          state[:adapter_opts]
        )

      assert resp == :ok

      {:ok, encoded_abi_data} = ABIEncoder.child_chain_erc20_deposit(tx_bytes)

      trx = decode_transaction_response(encoded_trx)
      sender_public_key = recover_public_key(trx)

      assert trx.data == encoded_abi_data
      assert Encoding.to_hex(sender_public_key) == "0x" <> state[:public_key]
      assert trx.gas_limit == GasHelper.get_gas_limit_or_default(:child_chain_deposit_token, %{})
      assert trx.gas_price == Application.get_env(:eth_blockchain, :default_gas_price)
      assert trx.value == 0
      assert Encoding.to_hex(trx.to) == state[:addr_1]
    end
  end

  describe "approve_erc20/2" do
    test "generates a desposit transaction for erc20 currency", state do
      amount = 100
      {resp, encoded_trx} =
        Transaction.approve_erc20(
          %{
            from: state[:valid_sender],
            to: state[:addr_1],
            amount: amount,
            contract_address: state[:addr_2]
          },
          state[:adapter_opts]
        )

      assert resp == :ok

      {:ok, encoded_abi_data} = ABIEncoder.approve(state[:addr_1], amount)

      trx = decode_transaction_response(encoded_trx)
      sender_public_key = recover_public_key(trx)

      assert trx.data == encoded_abi_data
      assert Encoding.to_hex(sender_public_key) == "0x" <> state[:public_key]
      assert trx.gas_limit == GasHelper.get_gas_limit_or_default(:contract_transaction, %{})
      assert trx.gas_price == Application.get_env(:eth_blockchain, :default_gas_price)
      assert trx.value == 0
      assert Encoding.to_hex(trx.to) == state[:addr_2]
    end
  end

  describe "deserialize/1" do
    test "returns the decoded RLP-encoded transaction" do
      deserialized =
        Transaction.deserialize([
          "",
          <<4, 168, 23, 200, 0>>,
          "R\b",
          <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
          "d",
          "",
          <<2, 193, 206>>,
          <<132, 50, 201, 31, 172, 179, 191, 32, 115, 195, 31, 236, 245, 18, 240, 161, 185, 98,
            151, 176, 179, 206, 94, 110, 26, 144, 24, 145, 38, 139, 9, 133>>,
          <<68, 44, 170, 60, 51, 238, 50, 26, 71, 237, 212, 7, 160, 164, 189, 233, 114, 84, 184,
            57, 240, 120, 183, 40, 193, 69, 42, 112, 253, 163, 237, 138>>
        ])

      assert deserialized == %Transaction{
               data: "",
               gas_limit: 21_000,
               gas_price: 20_000_000_000,
               init: "",
               nonce: 0,
               # credo:disable-for-lines:2 Credo.Check.Readability.MaxLineLength
               r:
                 59_795_026_471_191_791_691_553_212_152_080_426_284_599_024_569_572_292_875_880_667_924_209_261_545_861,
               # credo:disable-for-lines:2 Credo.Check.Readability.MaxLineLength
               s:
                 30_836_189_894_457_032_652_897_540_276_539_634_084_883_692_778_205_447_233_810_671_240_962_434_657_674,
               to: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1>>,
               v: 180_686,
               value: 100
             }
    end
  end
end
