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

defmodule EthGethAdapter.TransactionReceipt do
  @moduledoc """
  Represents a receipt of an ethereum transaction
  """

  import Utils.Helpers.Encoding

  alias Ethereumex.HttpClient, as: Client

  defstruct block_hash: nil,
            block_number: nil,
            contract_address: nil,
            cumulative_gas_used: 0,
            from: nil,
            gas_used: 0,
            logs: [],
            logs_bloom: nil,
            status: nil,
            to: nil,
            transaction_hash: nil,
            transaction_index: 0

  @type t :: %__MODULE__{
          block_hash: String.t(),
          block_number: integer(),
          contract_address: String.t(),
          cumulative_gas_used: integer(),
          from: String.t(),
          gas_used: integer(),
          logs: list(),
          logs_bloom: String.t(),
          status: integer(),
          to: String.t(),
          transaction_hash: String.t(),
          transaction_index: integer()
        }

  def get(transaction_hash) do
    transaction_hash
    |> Client.eth_get_transaction_receipt()
    |> parse_response()
  end

  defp parse_response({:ok, nil}) do
    {:ok, :not_found, nil}
  end

  defp parse_response({:ok, %{"status" => "0x0"} = receipt}) do
    {:ok, :failed, parse_receipt(receipt)}
  end

  defp parse_response({:ok, receipt}) do
    {:ok, :success, parse_receipt(receipt)}
  end

  defp parse_response({:error, %{"message" => message}}) do
    {:error, :adapter_error, message}
  end

  defp parse_receipt(receipt) do
    %__MODULE__{
      block_hash: receipt["blockHash"],
      block_number: int_from_hex(receipt["blockNumber"]),
      contract_address: receipt["contractAddress"],
      cumulative_gas_used: int_from_hex(receipt["cumulativeGasUsed"]),
      from: receipt["from"],
      gas_used: int_from_hex(receipt["gasUsed"]),
      logs: receipt["logs"],
      logs_bloom: receipt["logsBloom"],
      status: int_from_hex(receipt["status"]),
      to: receipt["to"],
      transaction_hash: receipt["transactionHash"],
      transaction_index: int_from_hex(receipt["transactionIndex"])
    }
  end
end
