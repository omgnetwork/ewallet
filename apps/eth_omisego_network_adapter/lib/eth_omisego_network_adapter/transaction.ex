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

defmodule EthOmisegoNetworkAdapter.Transaction do
  @moduledoc """
  Internal representation of transaction spent on Plasma chain.
  """
  import Utils.Helpers.Encoding

  alias EthOmisegoNetworkAdapter.HttpClient
  alias Keychain.Signature

  @eth "0x0000000000000000000000000000000000000000"
  @max_inputs 4
  @max_outputs 4

  defstruct [:inputs, :outputs]

  @doc """
  Creates a new transaction from a list of inputs and a list of outputs.
  Adds empty (zeroes) inputs and/or outputs to reach the expected size
  of `@max_inputs` inputs and `@max_outputs` outputs.

  assumptions:
  ```
    length(inputs) <= @max_inputs
    length(outputs) <= @max_outputs
  ```
  Returns {:ok, tx_bytes}
  """
  @spec get_deposit_tx_bytes(Sting.t(), integer(), String.t()) :: {:ok, String.t()}
  def get_deposit_tx_bytes(address, amount, currency) do
    tx_bytes =
      []
      |> new([{from_hex(address), from_hex(currency), amount}])
      |> encode()

    {:ok, tx_bytes}
  end

  @doc """
  This functions does 2 things internally:
  - Build the transaction with the UTXO to use by calling the `transaction.create`
  watcher's endpoint.
  - Submit the transaction along with the signatures by calling the
  `transaction.submit_typed` watcher's endpoint.

  Note: The fee is currently hardcoded to 1 wei.

  Returns
  {:ok, %{block_number: blknum, transaction_index: txindex, transaction_hash: txhash}}
  if success
  {:error, code} || {:error, code, params} if there was an error while communicating with
  the watcher.
  """
  @spec send(Sting.t(), Sting.t(), integer(), Sting.t()) ::
          {:ok, map()} | {:error, atom()} | {:error, atom(), any()}
  def send(from, to, amount, currency_address) do
    case prepare_transaction(from, to, amount, currency_address) do
      {:ok, %{"result" => "complete"} = create_response} ->
        create_response
        |> sign_and_submit(from)
        |> respond_submit()

      {:ok, %{"result" => "intermediate"} = create_response} ->
        create_response
        |> sign_and_submit(from)
        |> handle_intermediate()

      {:ok, _} ->
        {:error, :unhandled}

      error ->
        error
    end
  end

  defp sign_and_submit(
         %{
           "transactions" => [
             %{"sign_hash" => sign_hash, "typed_data" => typed_data, "inputs" => inputs} | _
           ]
         },
         from
       ) do
    sign_hash
    |> sign(from, inputs)
    |> submit_typed(typed_data)
  end

  defp handle_intermediate({:ok, _response}) do
    # TODO: Handle transactions that require a merge.
    # For now we are doing the merge on the childchain but the initiator needs to re-submit the transaction.
    {:error, :omisego_network_unhandled_merge_transaction}
  end

  defp handle_intermediate(error), do: error

  defp prepare_transaction(from, to, amount, currency_address) do
    # TODO: Fee?
    %{
      owner: from,
      payments: [
        %{
          amount: amount,
          currency: currency_address,
          owner: to
        }
      ],
      fee: %{
        amount: 1,
        currency: @eth
      }
    }
    |> Jason.encode!()
    |> HttpClient.post_request("transaction.create")
  end

  defp sign(sign_hash, from, inputs) do
    with {:ok, {v, r, s}} <- Signature.sign_transaction_hash(from_hex(sign_hash), from) do
      sig = to_hex(<<r::integer-size(256), s::integer-size(256), v::integer-size(8)>>)
      List.duplicate(sig, length(inputs))
    end
  end

  defp submit_typed({:error, _} = error, _), do: error

  defp submit_typed(signatures, typed_data) do
    typed_data
    |> Map.put_new("signatures", signatures)
    |> Jason.encode!()
    |> HttpClient.post_request("transaction.submit_typed")
  end

  defp new(inputs, outputs)
       when length(inputs) <= @max_inputs and length(outputs) <= @max_outputs do
    inputs =
      Enum.map(inputs, fn {blknum, txindex, oindex} ->
        %{blknum: blknum, txindex: txindex, oindex: oindex}
      end)

    inputs =
      inputs ++
        List.duplicate(%{blknum: 0, txindex: 0, oindex: 0}, @max_inputs - Kernel.length(inputs))

    outputs =
      Enum.map(outputs, fn {owner, currency, amount} ->
        %{owner: owner, currency: currency, amount: amount}
      end)

    outputs =
      outputs ++
        List.duplicate(
          %{owner: from_hex(@eth), currency: from_hex(@eth), amount: 0},
          @max_outputs - Kernel.length(outputs)
        )

    %__MODULE__{inputs: inputs, outputs: outputs}
  end

  defp encode(%__MODULE__{} = transaction) do
    transaction
    |> get_data_for_rlp()
    |> ExRLP.encode()
  end

  defp get_data_for_rlp(%__MODULE__{inputs: inputs, outputs: outputs}) do
    [
      # contract expects 4 inputs and outputs
      Enum.map(inputs, fn %{blknum: blknum, txindex: txindex, oindex: oindex} ->
        [blknum, txindex, oindex]
      end) ++
        List.duplicate([0, 0, 0], 4 - length(inputs)),
      Enum.map(outputs, fn %{owner: owner, currency: currency, amount: amount} ->
        [owner, currency, amount]
      end) ++
        List.duplicate([from_hex(@eth), from_hex(@eth), 0], 4 - length(outputs))
    ]
  end

  defp respond_submit({:ok, %{"blknum" => blknum, "txindex" => txindex, "txhash" => txhash}}) do
    {:ok, %{block_number: blknum, transaction_index: txindex, transaction_hash: txhash}}
  end

  defp respond_submit(error), do: error
end
