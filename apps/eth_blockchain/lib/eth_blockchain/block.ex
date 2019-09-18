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
  import Utils.Helpers.Encoding
  alias EthBlockchain.{AdapterServer, Helper}

  def get_number(opts \\ []) do
    case AdapterServer.eth_call({:get_block_number}, opts) do
      {:ok, number} -> {:ok, int_from_hex(number)}
      error -> error
    end
  end

  def get(number, opts \\ []) do
    AdapterServer.eth_call({:get_block, number}, opts)
  end

  def get_transactions(
        %{
          blk_number: blk_number
        } = attrs,
        opts \\ []
      ) do
    case get(blk_number, opts) do
      {:ok, nil} ->
        {:error, :block_not_found}

      {:ok, block} ->
        parse(block, attrs)

      error ->
        error
    end
  end

  defp parse(%{"transactions" => transactions}, %{
         addresses: addresses,
         contract_addresses: contract_addresses
       }) do
    Enum.reduce(transactions, [], fn transaction, acc ->
      cond do
        tracked_contract_transaction?(transaction, contract_addresses) ->
          handle_contract_transaction(transaction, addresses, acc)

        relevant_eth_transaction?(transaction, addresses) ->
          [format_eth_transaction(transaction) | acc]

        true ->
          acc
      end
    end)
  end

  defp handle_contract_transaction(transaction, addresses, acc) do
    case parse_input(transaction["input"]) do
      {to_address, amount} ->
        case Enum.member?(addresses, transaction["from"]) || Enum.member?(addresses, to_address) do
          true ->
            [format_contract_transaction(transaction, to_address, amount) | acc]

          false ->
            acc
        end

      _ ->
        acc
    end
  end

  defp relevant_eth_transaction?(transaction, addresses) do
    transaction_from_or_to?(transaction, addresses) && transaction_empty_input?(transaction)
  end

  defp transaction_from_or_to?(transaction, addresses) do
    Enum.member?(addresses, transaction["from"]) || Enum.member?(addresses, transaction["to"])
  end

  defp transaction_empty_input?(%{"input" => nil}), do: true
  defp transaction_empty_input?(%{"input" => "0x"}), do: true
  defp transaction_empty_input?(_), do: false

  defp tracked_contract_transaction?(transaction, contract_addresses) do
    Enum.member?(contract_addresses, transaction["to"])
  end

  defp parse_input(input) do
    case get_data(input) do
      nil ->
        nil

      data ->
        [to_address, amount] = ABI.decode("transfer(address,uint)", data)
        {to_hex(to_address), amount}
    end
  end

  defp get_data("0x" <> <<_function::binary-size(8)>> <> data) do
    from_hex(data)
  end

  defp get_data(_), do: nil

  defp format_contract_transaction(transaction, to_address, amount) do
    transaction
    |> format_eth_transaction()
    |> Map.put(:contract_address, transaction["to"])
    |> Map.put(:amount, amount)
    |> Map.put(:to, to_address)
  end

  defp format_eth_transaction(transaction) do
    {:ok, current_block_number} = get_number()
    block_number = int_from_hex(transaction["blockNumber"])

    %{
      block_hash: transaction["blockHash"],
      block_number: block_number,
      from: transaction["from"],
      to: transaction["to"],
      amount: int_from_hex(transaction["value"]),
      contract_address: Helper.default_token().address,
      gas: int_from_hex(transaction["gas"]),
      gas_price: int_from_hex(transaction["gasPrice"]),
      hash: transaction["hash"],
      index: int_from_hex(transaction["transactionIndex"]),
      nonce: int_from_hex(transaction["nonce"]),
      confirmations_count: current_block_number - block_number + 1,
      data: get_data(transaction["input"])
    }
  end
end
