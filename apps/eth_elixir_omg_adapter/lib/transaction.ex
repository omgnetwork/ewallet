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

# TODO: Move in new subapp
defmodule EthElixirOmgAdapter.Transaction do
  @moduledoc """
  Internal representation of transaction spent on Plasma chain.
  """
  import Utils.Helpers.Encoding

  alias EthElixirOmgAdapter.HttpClient

  @eth EthBlockchain.Helper.default_address()
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
  """

  def get_deposit_tx_bytes(address, amount, currency) do
    []
    |> new([{from_hex(address), from_hex(currency), amount}])
    |> encode()
  end

  def send(from, to, amount, currency_address) do
    case prepare_transaction(from, to, amount, currency_address) do
      # Handling only complete transactions
      {:ok,
       %{
         "result" => "complete",
         "transactions" => [%{"sign_hash" => sign_hash, "typed_data" => typed_data} | _]
       }} ->
        sign_hash
        |> sign(from)
        |> submit_typed(typed_data)

      # TODO Handle intermediate transactions
      {:ok, %{"result" => "intermediate"}} ->
        {:error, :todo}

      {:ok, _} ->
        {:error, :unhandled}

      error ->
        error
    end
  end

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
        amount: 0,
        currency: "0x0000000000000000000000000000000000000000"
      }
    }
    |> Jason.encode!()
    |> HttpClient.post_request("transaction.create")
  end

  defp sign(sign_hash, from) do
    {:ok, {v, r, s}} = Keychain.Signature.sign_transaction_hash(from_hex(sign_hash), from)
    to_hex(<<r::integer-size(256), s::integer-size(256), v::integer-size(8)>>)
  end

  defp submit_typed(signature, typed_data) do
    typed_data
    |> Map.put_new("signatures", [signature])
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

  @doc """
  Returns the encoded bytes of the raw transaction
  """
  defp encode(%__MODULE__{} = transaction) do
    transaction
    |> get_data_for_rlp()
    |> ExRLP.encode()
  end

  @doc """
  Turns a structure instance into a structure of RLP items, ready to be RLP encoded, for a raw transaction
  """
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
end
