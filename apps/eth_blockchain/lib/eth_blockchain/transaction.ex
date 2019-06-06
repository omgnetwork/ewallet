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

defmodule EthBlockchain.Transaction do
  @moduledoc false

  import Utils.Helpers.Encoding

  alias Keychain.Signature
  alias ExthCrypto.Hash.Keccak
  alias EthBlockchain.{Adapter, ABI}

  defstruct nonce: 0,
            gas_price: 0,
            gas_limit: 0,
            to: <<>>,
            value: 0,
            v: nil,
            r: nil,
            s: nil,
            init: <<>>,
            data: <<>>

  @type t :: %__MODULE__{
          nonce: EVM.val(),
          gas_price: EVM.val(),
          gas_limit: EVM.val(),
          to: EVM.address() | <<_::0>>,
          value: EVM.val(),
          v: Signature.hash_v(),
          r: Signature.hash_r(),
          s: Signature.hash_s(),
          init: EVM.MachineCode.t(),
          data: binary()
        }

  def send_eth({from_address, to_address, amount}, adapter \\ nil, pid \\ nil) do
    transaction_data =
      %__MODULE__{
        # todo
        gas_limit: 21_000,
        # todo
        gas_price: 20_000_000_000,
        nonce: get_next_nonce(from_address),
        to: from_hex(to_address),
        value: amount
      }
      |> sign_and_hash(from_address)

    Adapter.call(adapter, {:send_raw, transaction_data}, pid)
  end

  def send_token({from_address, to_address, amount, contract_address}, adapter \\ nil, pid \\ nil) do
    case ABI.transfer(to_address, amount) do
      {:ok, encoded_abi_data} ->
        transaction_data =
          %__MODULE__{
            # todo
            gas_limit: 50_000_000,
            # todo
            gas_price: 20_000_000_000,
            nonce: get_next_nonce(from_address),
            to: from_hex(contract_address),
            data: encoded_abi_data
          }
          |> sign_and_hash(from_address)

        Adapter.call(adapter, {:send_raw, transaction_data}, pid)

      error ->
        error
    end
  end

  defp sign_and_hash(%__MODULE__{} = transaction_data, from_address) do
    transaction_data
    |> sign_transaction(from_address)
    |> serialize()
    |> ExRLP.encode()
    |> to_hex()
  end

  @spec get_transaction_count(
          {String.t()},
          atom() | nil,
          pid() | nil
        ) :: {:error, atom()} | {:ok, any()}
  def get_transaction_count({address}, adapter \\ nil, pid \\ nil) do
    Adapter.call(adapter, {:get_transaction_count, address}, pid)
  end

  defp get_next_nonce(address) do
    {:ok, nonce} = get_transaction_count({address})
    int_from_hex(nonce)
  end

  defp sign_transaction(transaction, wallet_address) do
    {v, r, s} =
      transaction
      |> transaction_hash(1)
      |> Signature.sign_transaction_hash(wallet_address, 1)

    %{transaction | v: v, r: r, s: s}
  end

  @spec transaction_hash(Blockchain.Transaction.t()) :: Keccak.keccak_hash()
  defp transaction_hash(trx, chain_id \\ nil) do
    trx
    |> serialize(false)
    |> Kernel.++(if chain_id, do: [encode_unsigned(chain_id), <<>>, <<>>], else: [])
    |> ExRLP.encode()
    |> Keccak.kec()
  end

  @doc """
  Encodes a transaction such that it can be RLP-encoded.
  This is defined at L_T Eq.(14) in the Yellow Paper.
  ## Examples
      iex> Blockchain.Transaction.serialize(%Blockchain.Transaction{nonce: 5, gas_price: 6, gas_limit: 7, to: <<1::160>>, value: 8, v: 27, r: 9, s: 10, data: "hi"})
      [<<5>>, <<6>>, <<7>>, <<1::160>>, <<8>>, "hi", <<27>>, <<9>>, <<10>>]
      iex> Blockchain.Transaction.serialize(%Blockchain.Transaction{nonce: 5, gas_price: 6, gas_limit: 7, to: <<>>, value: 8, v: 27, r: 9, s: 10, init: <<1, 2, 3>>})
      [<<5>>, <<6>>, <<7>>, <<>>, <<8>>, <<1, 2, 3>>, <<27>>, <<9>>, <<10>>]
      iex> Blockchain.Transaction.serialize(%Blockchain.Transaction{nonce: 5, gas_price: 6, gas_limit: 7, to: <<>>, value: 8, v: 27, r: 9, s: 10, init: <<1, 2, 3>>}, false)
      [<<5>>, <<6>>, <<7>>, <<>>, <<8>>, <<1, 2, 3>>]
      iex> Blockchain.Transaction.serialize(%Blockchain.Transaction{ data: "", gas_limit: 21000, gas_price: 20000000000, init: "", nonce: 9, r: 0, s: 0, to: "55555555555555555555", v: 1, value: 1000000000000000000 })
      ["\t", <<4, 168, 23, 200, 0>>, "R\b", "55555555555555555555", <<13, 224, 182, 179, 167, 100, 0, 0>>, "", <<1>>, "", ""]
  """
  @spec serialize(t) :: ExRLP.t()
  def serialize(trx, include_vrs \\ true) do
    base = [
      trx.nonce |> encode_unsigned(),
      trx.gas_price |> encode_unsigned(),
      trx.gas_limit |> encode_unsigned(),
      trx.to,
      trx.value |> encode_unsigned(),
      if(trx.to == <<>>, do: trx.init, else: trx.data)
    ]

    if include_vrs do
      base ++
        [
          trx.v |> encode_unsigned(),
          trx.r |> encode_unsigned(),
          trx.s |> encode_unsigned()
        ]
    else
      base
    end
  end

  @doc """
  Decodes a transaction that was previously encoded
  using `Transaction.serialize/1`. Note, this is the
  inverse of L_T Eq.(14) defined in the Yellow Paper.
  ## Examples
      iex> Blockchain.Transaction.deserialize([<<5>>, <<6>>, <<7>>, <<1::160>>, <<8>>, "hi", <<27>>, <<9>>, <<10>>])
      %Blockchain.Transaction{nonce: 5, gas_price: 6, gas_limit: 7, to: <<1::160>>, value: 8, v: 27, r: 9, s: 10, data: "hi"}
      iex> Blockchain.Transaction.deserialize([<<5>>, <<6>>, <<7>>, <<>>, <<8>>, <<1, 2, 3>>, <<27>>, <<9>>, <<10>>])
      %Blockchain.Transaction{nonce: 5, gas_price: 6, gas_limit: 7, to: <<>>, value: 8, v: 27, r: 9, s: 10, init: <<1, 2, 3>>}
      iex> Blockchain.Transaction.deserialize(["\t", <<4, 168, 23, 200, 0>>, "R\b", "55555555555555555555", <<13, 224, 182, 179, 167, 100, 0, 0>>, "", <<1>>, "", ""])
      %Blockchain.Transaction{
        data: "",
        gas_limit: 21000,
        gas_price: 20000000000,
        init: "",
        nonce: 9,
        r: 0,
        s: 0,
        to: "55555555555555555555",
        v: 1,
        value: 1000000000000000000
      }
  """
  @spec deserialize(ExRLP.t()) :: t
  def deserialize(rlp) do
    [
      nonce,
      gas_price,
      gas_limit,
      to,
      value,
      init_or_data,
      v,
      r,
      s
    ] = rlp

    {init, data} = if to == <<>>, do: {init_or_data, <<>>}, else: {<<>>, init_or_data}

    %__MODULE__{
      nonce: :binary.decode_unsigned(nonce),
      gas_price: :binary.decode_unsigned(gas_price),
      gas_limit: :binary.decode_unsigned(gas_limit),
      to: to,
      value: :binary.decode_unsigned(value),
      init: init,
      data: data,
      v: :binary.decode_unsigned(v),
      r: :binary.decode_unsigned(r),
      s: :binary.decode_unsigned(s)
    }
  end
end
