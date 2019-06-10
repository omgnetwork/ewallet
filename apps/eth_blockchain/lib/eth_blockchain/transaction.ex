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
          nonce: integer(),
          gas_price: integer(),
          gas_limit: integer(),
          to: String.t(),
          value: integer(),
          v: Signature.hash_v(),
          r: Signature.hash_r(),
          s: Signature.hash_s(),
          init: binary(),
          data: binary()
        }

  @spec send_eth(tuple(), atom() | nil, pid() | nil) :: {atom(), String.t()}
  def send_eth(params, adapter \\ nil, pid \\ nil)

  def send_eth({from_address, to_address, amount}, adapter, pid) do
    gas_price = Application.get_env(:eth_blockchain, :default_gas_price)
    send_eth({from_address, to_address, amount, gas_price}, adapter, pid)
  end

  def send_eth({from_address, to_address, amount, gas_price}, adapter, pid)
      when byte_size(from_address) == 42 and byte_size(to_address) == 42 and is_integer(amount) do
    %__MODULE__{
      gas_limit: Application.get_env(:eth_blockchain, :default_eth_transaction_gas_limit),
      gas_price: gas_price,
      nonce: get_next_nonce(from_address),
      to: from_hex(to_address),
      value: amount
    }
    |> sign_and_hash(from_address)
    |> send_raw(adapter, pid)
  end

  def send_eth({_from, _to, _amount, _gas_price}, _adapter, _pid) do
    {:error, "Invalid parameters"}
  end

  @spec send_token(tuple(), atom() | nil, pid() | nil) :: {atom(), String.t()} | {atom(), atom()}
  def send_token(params, adapter \\ nil, pid \\ nil)

  def send_token({from_address, to_address, amount, contract_address}, adapter, pid) do
    gas_price = Application.get_env(:eth_blockchain, :default_gas_price)
    send_token({from_address, to_address, amount, contract_address, gas_price}, adapter, pid)
  end

  def send_token({from_address, to_address, amount, contract_address, gas_price}, adapter, pid)
      when byte_size(from_address) == 42 and byte_size(to_address) == 42 and
             byte_size(contract_address) == 42 and is_integer(amount) do
    case ABI.transfer(to_address, amount) do
      {:ok, encoded_abi_data} ->
        %__MODULE__{
          gas_limit:
            Application.get_env(:eth_blockchain, :default_contract_transaction_gas_limit),
          gas_price: gas_price,
          nonce: get_next_nonce(from_address),
          to: from_hex(contract_address),
          data: encoded_abi_data
        }
        |> sign_and_hash(from_address)
        |> send_raw(adapter, pid)

      error ->
        error
    end
  end

  def send_token({_from, _to, _amount, _contract, _gas_price}, _adapter, _pid) do
    {:error, "Invalid parameters"}
  end

  defp sign_and_hash(%__MODULE__{} = transaction_data, from_address) do
    case sign_transaction(transaction_data, from_address) do
      {:error, _e} = error ->
        error

      %__MODULE__{} = signed_trx ->
        signed_trx
        |> serialize()
        |> ExRLP.encode()
        |> to_hex()
    end
  end

  defp send_raw({:error, _e} = error, _adapter, _pid), do: error

  defp send_raw(transaction_data, adapter, pid) do
    Adapter.call(adapter, {:send_raw, transaction_data}, pid)
  end

  @spec get_transaction_count({String.t()}, atom() | nil, pid() | nil) :: {atom(), any()}
  def get_transaction_count({address}, adapter \\ nil, pid \\ nil) do
    Adapter.call(adapter, {:get_transaction_count, address}, pid)
  end

  defp get_next_nonce(address) do
    {:ok, nonce} = get_transaction_count({address})
    int_from_hex(nonce)
  end

  defp sign_transaction(transaction, wallet_address) do
    chain_id = Application.get_env(:eth_blockchain, :chain_id)

    result =
      transaction
      |> transaction_hash(chain_id)
      |> Signature.sign_transaction_hash(wallet_address, chain_id)

    case result do
      {:error, _e} = error -> error
      {v, r, s} -> %{transaction | v: v, r: r, s: s}
    end
  end

  @spec transaction_hash(Blockchain.Transaction.t(), integer()) :: Keccak.keccak_hash()
  defp transaction_hash(trx, chain_id) do
    trx
    |> serialize(false)
    |> Kernel.++([encode_unsigned(chain_id), <<>>, <<>>])
    |> ExRLP.encode()
    |> Keccak.kec()
  end

  defp serialize(trx, include_vrs \\ true) do
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
end
