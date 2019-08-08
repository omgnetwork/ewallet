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

defmodule EthBlockchain.Plasma.Transaction do
  @moduledoc """
  Internal representation of transaction spent on Plasma chain.
  """

  alias Utils.Helpers.Encoding

  @zero_address Encoding.from_hex(EthBlockchain.Helper.default_address())
  @max_inputs 4
  @max_outputs 4

  @default_metadata nil

  defstruct [:inputs, :outputs, metadata: @default_metadata]

  defmacro is_metadata(metadata) do
    quote do
      unquote(metadata) == nil or
        (is_binary(unquote(metadata)) and byte_size(unquote(metadata)) == 32)
    end
  end

  defmacro max_inputs do
    quote do
      unquote(@max_inputs)
    end
  end

  defmacro max_outputs do
    quote do
      unquote(@max_outputs)
    end
  end

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
  def new(inputs, outputs, metadata \\ @default_metadata)

  def new(inputs, outputs, metadata)
      when is_metadata(metadata) and length(inputs) <= @max_inputs and
             length(outputs) <= @max_outputs do
    inputs =
      inputs
      |> Enum.map(fn {blknum, txindex, oindex} ->
        %{blknum: blknum, txindex: txindex, oindex: oindex}
      end)

    inputs =
      inputs ++
        List.duplicate(%{blknum: 0, txindex: 0, oindex: 0}, @max_inputs - Kernel.length(inputs))

    outputs =
      outputs
      |> Enum.map(fn {owner, currency, amount} ->
        %{owner: owner, currency: currency, amount: amount}
      end)

    outputs =
      outputs ++
        List.duplicate(
          %{owner: @zero_address, currency: @zero_address, amount: 0},
          @max_outputs - Kernel.length(outputs)
        )

    %__MODULE__{inputs: inputs, outputs: outputs, metadata: metadata}
  end

  @doc """
  Transaform the structure of RLP items after a successful RLP decode of a raw transaction, into a structure instance
  """
  def reconstruct([inputs_rlp, outputs_rlp | rest_rlp])
      when rest_rlp == [] or length(rest_rlp) == 1 do
    with {:ok, inputs} <- reconstruct_inputs(inputs_rlp),
         {:ok, outputs} <- reconstruct_outputs(outputs_rlp),
         {:ok, metadata} <- reconstruct_metadata(rest_rlp),
         do: {:ok, %__MODULE__{inputs: inputs, outputs: outputs, metadata: metadata}}
  end

  def reconstruct(_), do: {:error, :malformed_transaction}

  defp reconstruct_inputs(inputs_rlp) do
    Enum.map(inputs_rlp, fn [blknum, txindex, oindex] ->
      %{blknum: parse_int(blknum), txindex: parse_int(txindex), oindex: parse_int(oindex)}
    end)
    |> inputs_without_gaps()
  rescue
    _ -> {:error, :malformed_inputs}
  end

  defp reconstruct_outputs(outputs_rlp) do
    outputs =
      Enum.map(outputs_rlp, fn [owner, currency, amount] ->
        with {:ok, cur12} <- parse_address(currency),
             {:ok, owner} <- parse_address(owner) do
          %{owner: owner, currency: cur12, amount: parse_int(amount)}
        end
      end)

    if(error = Enum.find(outputs, &match?({:error, _}, &1)),
      do: error,
      else: outputs
    )
    |> outputs_without_gaps()
  rescue
    _ -> {:error, :malformed_outputs}
  end

  defp reconstruct_metadata([]), do: {:ok, nil}
  defp reconstruct_metadata([metadata]) when is_metadata(metadata), do: {:ok, metadata}
  defp reconstruct_metadata([_]), do: {:error, :malformed_metadata}

  defp parse_int(binary), do: :binary.decode_unsigned(binary, :big)

  # necessary, because RLP handles empty string equally to integer 0
  defp parse_address(binary)
  defp parse_address(""), do: {:ok, <<0::160>>}
  defp parse_address(<<_::160>> = address_bytes), do: {:ok, address_bytes}
  defp parse_address(_), do: {:error, :malformed_address}

  def decode(tx_bytes) do
    with {:ok, raw_tx_rlp_decoded_chunks} <- try_exrlp_decode(tx_bytes),
         do: reconstruct(raw_tx_rlp_decoded_chunks)
  end

  def decode!(tx_bytes) do
    {:ok, tx} = decode(tx_bytes)
    tx
  end

  defp try_exrlp_decode(tx_bytes) do
    {:ok, ExRLP.decode(tx_bytes)}
  rescue
    _ -> {:error, :malformed_transaction_rlp}
  end

  defp encode(transaction) do
    get_data_for_rlp(transaction)
    |> ExRLP.encode()
  end

  @doc """
  Turns a structure instance into a structure of RLP items, ready to be RLP encoded, for a raw transaction
  """
  def get_data_for_rlp(%__MODULE__{inputs: inputs, outputs: outputs, metadata: metadata})
      when is_metadata(metadata),
      do:
        [
          # contract expects 4 inputs and outputs
          Enum.map(inputs, fn %{blknum: blknum, txindex: txindex, oindex: oindex} ->
            [blknum, txindex, oindex]
          end) ++
            List.duplicate([0, 0, 0], 4 - length(inputs)),
          Enum.map(outputs, fn %{owner: owner, currency: currency, amount: amount} ->
            [owner, currency, amount]
          end) ++
            List.duplicate([@zero_address, @zero_address, 0], 4 - length(outputs))
        ] ++ if(metadata, do: [metadata], else: [])

  defp hash(%__MODULE__{} = tx) do
    tx
    |> encode
    |> Crypto.hash()
  end

  @doc """
  Returns all inputs, never returns zero inputs
  """
  # def get_inputs(%__MODULE__.Recovered{signed_tx: signed_tx}), do: get_inputs(signed_tx)
  # def get_inputs(%__MODULE__.Signed{raw_tx: raw_tx}), do: get_inputs(raw_tx)

  # def get_inputs(%__MODULE__{inputs: inputs}) do
  #   inputs
  #   |> Enum.map(fn %{blknum: blknum, txindex: txindex, oindex: oindex} -> Utxo.position(blknum, txindex, oindex) end)
  #   |> Enum.filter(&Utxo.Position.non_zero?/1)
  # end

  @doc """
  Returns all outputs, never returns zero outputs
  """
  # def get_outputs(%__MODULE__.Recovered{signed_tx: signed_tx}), do: get_outputs(signed_tx)
  # def get_outputs(%__MODULE__.Signed{raw_tx: raw_tx}), do: get_outputs(raw_tx)

  # def get_outputs(%__MODULE__{outputs: outputs}) do
  #   outputs
  #   |> Enum.reject(&match?(%{owner: @zero_address, currency: @zero_address, amount: 0}, &1))
  # end

  @doc """
  Returns the encoded bytes of the raw transaction involved, i.e. without the signatures
  """
  def raw_txbytes(%__MODULE__{} = raw_tx), do: encode(raw_tx)

  @doc """
  Returns the hash of the raw transaction involved, i.e. without the signatures
  """
  def raw_txhash(%__MODULE__{} = raw_tx), do: hash(raw_tx)

  defp inputs_without_gaps(inputs),
    do:
      check_for_gaps(inputs, %{blknum: 0, txindex: 0, oindex: 0}, {:error, :inputs_contain_gaps})

  defp outputs_without_gaps({:error, _} = error), do: error

  defp outputs_without_gaps(outputs),
    do:
      check_for_gaps(
        outputs,
        %{owner: @zero_address, currency: @zero_address, amount: 0},
        {:error, :outputs_contain_gaps}
      )

  # Check if any consecutive pair of elements contains empty followed by non-empty element
  # which means there is a gap
  defp check_for_gaps(items, empty, error) do
    items
    # discard - discards last unpaired element from a comparison
    |> Stream.chunk_every(2, 1, :discard)
    |> Enum.any?(fn
      [^empty, elt] when elt != empty -> true
      _ -> false
    end)
    |> if(do: error, else: {:ok, items})
  end
end
