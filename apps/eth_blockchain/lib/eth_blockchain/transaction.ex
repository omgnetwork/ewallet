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

  alias Keychain.Signature
  alias ExthCrypto.Hash.Keccak
  alias EthBlockchain.Adapter

  defstruct nonce: 0,
            # Tn
            # Tp
            gas_price: 0,
            # Tg
            gas_limit: 0,
            # Tt
            to: <<>>,
            # Tv
            value: 0,
            # Tw
            v: nil,
            # Tr
            r: nil,
            # Ts
            s: nil,
            # Ti
            init: <<>>,
            # Td
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

  def send({from_address, to_address, amount}, adapter \\ nil, pid \\ nil) do
    # abi_encoded_data =
    #   ABI.encode("transferFrom(address,address,uint)", [from_address, to_address, token_id])

    # contract_address = "0x123" |> String.slice(2..-1) |> Base.decode16(case: :mixed)

    transaction_data =
      %__MODULE__{
        # data: abi_encoded_data,
        gas_limit: 100_000,
        gas_price: 16_000_000_000,
        init: <<>>,
        nonce: 5,
        to: to_address,#contract_address,
        value: amount
      }
      |> sign_transaction(from_address)
      |> serialize()
      |> ExRLP.encode()
      |> Base.encode16(case: :lower)

    adapter =
      adapter ||
        :eth_blockchain
        |> Application.get_env(EthBlockchain.Adapter)
        |> Keyword.get(:default_adapter)

    case pid do
      nil ->
        Adapter.call(adapter, {:send, transaction_data})

      p when is_pid(p) ->
        Adapter.call(adapter, {:send, transaction_data}, p)
    end
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
    serialize(trx, false)
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

  @doc """
  Similar to `:binary.encode_unsigned/1`, except we encode `0` as
  `<<>>`, the empty string. This is because the specification says that
  we cannot have any leading zeros, and so having <<0>> by itself is
  leading with a zero and prohibited.
  ## Examples
      iex> BitHelper.encode_unsigned(0)
      <<>>
      iex> BitHelper.encode_unsigned(5)
      <<5>>
      iex> BitHelper.encode_unsigned(5_000_000)
      <<76, 75, 64>>
  """
  @spec encode_unsigned(number()) :: binary()
  def encode_unsigned(0), do: <<>>
  def encode_unsigned(n), do: :binary.encode_unsigned(n)
end
