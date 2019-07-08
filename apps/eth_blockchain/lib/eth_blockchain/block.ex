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

defmodule EthBlockchain.Block do
  @moduledoc false

  alias EthBlockchain.{Adapter, BlockParser}

  def get_number(adapter \\ nil, pid \\ nil) do
    Adapter.call({:get_block_number}, adapter, pid)
  end

  def get(number, adapter \\ nil, pid \\ nil) do
    Adapter.call({:get_block, number}, adapter, pid)
  end

  def get_transactions(
        %{
          blk_number: blk_number,
          addresses: addresses,
          contract_addresses: contract_addresses
        } = attrs,
        adapter \\ nil,
        pid \\ nil
      ) do

    case get(blk_number, adapter, pid) do
      {:ok, block} ->
        parse(block, attrs)
      _ ->
        # TODO: handle error @mederic
    end
  end

  defp parse(%{"transactions" => transactions} = block, %{
      addresses: addresses,
      contract_addresses: contract_addresses
    }) do
      Enum.reduce(transactions, [], fn transaction, acc ->

        case relevant_transaction?(transaction, addresses, contract_addresses) do
          true ->
            parse_input(transaction["input"])

            case Enum.member?(addresses, parsed_input["to"]) do
              true ->
                [transaction | acc]
              false ->
                acc
            end
          false ->
            acc
        end
      end)
    end
  end

  defp relevant_transaction?(transaction, addresses, contract_addresses) do
    Enum.member?(addresses, transaction["from"]) ||
      Enum.member?(addresses, transaction["to"]) ||
      Enum.member?(contract_addresses, transaction["to"])
  end

  defp parse_input(input) do
    "0x" <> <<_function::binary-size(8)>> <> data = input
    [address, amount] = ABI.decode("transfer(address,uint)", from_hex(data))
  end

  defp parse_transaction(transaction) do
    %{
      block_hash: transaction["blockHash"],
      block_number: int_from_hex(transaction["blockNumber"]),
      from: transaction["from"],

      to: transaction["to"],
      amount: int_from_hex(transaction("value")),
      contract_address: "0x00000",

      gas: int_from_hex(transaction["gas"]),
      gas_price: int_from_hex(transaction["gasPrice"]),
      transaction_hash: transaction["hash"],
      transaction_index: int_from_hex(transaction["transactionIndex"]),
      nonce: int_from_hex(transaction("nonce")),
      input: transaction("input"),
    }
  end
end


        # TOKEN
        # %{
        #   "blockHash" => "0x517cf667a0289dfb4da33c6781f851b1cf6f20f1a23d3227b5235faf3953df82",
        #   "blockNumber" => "0x1163",
        #   "from" => "0x7de7570b0b7d6ca94fb48c82dfeb61a193aa336d",
        #   "gas" => "0x7530",
        #   "gasPrice" => "0x4a817c800",
        #   "hash" => "0x04d317a108fa20ec8e63aa83009cc24bd3a7e0f3cce07b22902265e1b7cdc526",
        #   "input" => "0xa9059cbb000000000000000000000000fc9350fca21aab1d52c1e39e913d9bc332a1df9f0000000000000000000000000000000000000000000000000000000000000001",
        #   "nonce" => "0xb",
        #   "r" => "0xb05c969d3b27ffb3cb61c6e2ca1ef318a349c8a26194810546c39614a833a264",
        #   "s" => "0x297d4fdf934cef07535bc3953b8639e43fbf3b32bb1d68e2ed9690d851fe74ee",
        #   "to" => "0x36c8dcfe2e42048e35bfe22e0ae969ce74223d5c",
        #   "transactionIndex" => "0x0",
        #   "v" => "0x2c1ce",
        #   "value" => "0x0"
        # }



        # %{
        #   "blockHash" => "0xead7d63c2e78b7a35ff9d9b7b75c1945c1a7cce657fdcf01ea4c75dbcc915f62",
        #   "blockNumber" => "0x116a",
        #   "from" => "0x7de7570b0b7d6ca94fb48c82dfeb61a193aa336d",
        #   "gas" => "0x7530",
        #   "gasPrice" => "0x4a817c800",
        #   "hash" => "0x9002e9c8547d631c880399439aa8b234f0aa0566f9b8a859b6dc6e2f82674bd0",
        #   "input" => "0xa9059cbb000000000000000000000000fc9350fca21aab1d52c1e39e913d9bc332a1df9f0000000000000000000000000000000000000000000000000000000000000001",
        #   "nonce" => "0xc",
        #   "r" => "0x4ab2bd948340027e4283ea01395173f6b7b4db81c4d0fc5bb05bc430e06a7668",
        #   "s" => "0x50d66b5b557e377876b1c6f77fedc19103d4b95d0969f14b7f16b627d4a79985",
        #   "to" => "0x36c8dcfe2e42048e35bfe22e0ae969ce74223d5c",
        #   "transactionIndex" => "0x0",
        #   "v" => "0x2c1ce",
        #   "value" => "0x0"
        # }
        # IO.inspect(block)
