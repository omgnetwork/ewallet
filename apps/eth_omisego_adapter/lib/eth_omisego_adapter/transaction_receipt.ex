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

defmodule EthOmiseGOAdapter.TransactionReceipt do
  @moduledoc """
  Represents a receipt of a plasma omg transaction
  """

  alias EthOmiseGOAdapter.HTTPClient

  defstruct eth_block: nil,
            cc_block_number: 0,
            inputs: [],
            outputs: [],
            metadata: nil,
            transaction_bytes: nil,
            transaction_hash: nil,
            transaction_index: 0

  @type t :: %__MODULE__{
          eth_block: map(),
          cc_block_number: integer(),
          inputs: list(),
          outputs: list(),
          metadata: String.t(),
          transaction_bytes: String.t(),
          transaction_hash: String.t(),
          transaction_index: integer()
        }

  @doc """
  Attempts to get the transaction receipt for the specified hash.
  Note that with the current implementation of plasma, this will return
  {:ok, :not_found} for a submitted transaction but not yet included in the rootchain.
  Returns
  {:ok, :success, parsed_transaction} if the transaction is found on plasma
  {:ok, not_found} if the transaction is not yet included or the transaction does not exist
  {:error, code} || {:error, code, params} if there was an error while communicating with
  the watcher.
  """
  @spec get(Sting.t()) ::
          {:ok, :success, t()} | {:ok, :not_found} | {:error, atom()} | {:error, atom(), any()}
  def get(transaction_hash) do
    %{
      id: transaction_hash
    }
    |> Jason.encode!()
    |> HTTPClient.post_request("transaction.get")
    |> parse_response()
  end

  defp parse_response({:ok, transaction}) do
    {:ok, :success, parse_transaction(transaction)}
  end

  defp parse_response(
         {:error, :omisego_network_bad_request, [error_code: "transaction:not_found"]}
       ) do
    {:ok, :not_found}
  end

  defp parse_response(error), do: error

  defp parse_transaction(transaction) do
    %__MODULE__{
      eth_block: %{
        number: transaction["block"]["eth_height"],
        hash: transaction["block"]["hash"],
        timestamp: transaction["block"]["timestamp"]
      },
      cc_block_number: transaction["block"]["blknum"],
      inputs: parse_utxos(transaction["inputs"]),
      outputs: parse_utxos(transaction["outputs"]),
      metadata: transaction["metadata"],
      transaction_bytes: transaction["txbytes"],
      transaction_hash: transaction["txhash"],
      transaction_index: transaction["txindex"]
    }
  end

  defp parse_utxos(utxos) do
    Enum.map(utxos, fn utxo ->
      %{
        amount: utxo["amount"],
        block_number: utxo["blknum"],
        currency: utxo["currency"],
        oindex: utxo["oindex"],
        owner: utxo["owner"],
        transaction_index: utxo["txindex"],
        utxo_position: utxo["utxo_pos"]
      }
    end)
  end
end
