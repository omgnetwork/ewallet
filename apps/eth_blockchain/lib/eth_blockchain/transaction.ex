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
  alias EthBlockchain.{Adapter, ABIEncoder}

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
          to: String.t() | <<_::0>>,
          value: integer(),
          v: Signature.hash_v(),
          r: Signature.hash_r(),
          s: Signature.hash_s(),
          init: binary(),
          data: binary()
        }

  @doc """
  Initiate a token transfer between from `from` to `to` of the given amount.
  Ether is represented with `0x0000000000000000000000000000000000000000` as contract address and will be used as the default currency if no contract address specified.
  The gas price can be optionally specied, will default to the configued `:default_gas_price` if ommited.
  Possible map attrs:
  /3 %{:from, :to, :amount}
    -> will transfer `amount` ether from `from` to `to` with the default gas price
  /4 %{:from, :to, :amount, :gas_price}
    -> will transfer `amount` ether from `from` to `to` with the specified gas price
  /4 %{:from, :to, :amount, :contract_addr}
    -> will transfer `amount` token using the ERC20 contract residing at `contract_addr`
    from `from_addr` to `to` with the default gas price
  /5 %{:from, :to, :amount, :contract_address, :gas_price}
    ->
      if contract_addr is `0x0000000000000000000000000000000000000000`:
        will transfer `amount` ether from `from_addr` to `to_addr` with the specified gas price
      otherwise:
        will transfer `amount` token using the ERC20 contract residing at `contract_addr`
        from `from_addr` to `to_addr` with the specified gas price

  Returns:
  `{:ok, tx_hash}` if successful
  or
  `{:error, error_code}` or `{:error, error_code, message}` if failed
  """
  @spec send(map(), atom() | nil, pid() | nil) ::
          {atom(), String.t()} | {atom(), atom()} | {atom(), atom(), String.t()}
  def send(attrs, adapter \\ nil, pid \\ nil)

  def send(
        %{contract_address: "0x0000000000000000000000000000000000000000"} = attrs,
        adapter,
        pid
      ) do
    send_eth(attrs, adapter, pid)
  end

  def send(
        %{contract_address: _} = attrs,
        adapter,
        pid
      ) do
    send_token(attrs, adapter, pid)
  end

  def send(
        attrs,
        adapter,
        pid
      ) do
    send_eth(attrs, adapter, pid)
  end

  defp send_eth(
         %{
           from: from,
           to: to,
           amount: amount
         } = attrs,
         adapter,
         pid
       ) do
    gas_limit = Application.get_env(:eth_blockchain, :default_eth_transaction_gas_limit)
    gas_price = get_gas_price_or_default(attrs)

    case get_transaction_count(%{address: from}, adapter, pid) do
      {:ok, nonce} ->
        %__MODULE__{
          gas_limit: gas_limit,
          gas_price: gas_price,
          nonce: int_from_hex(nonce),
          to: from_hex(to),
          value: amount
        }
        |> sign_and_hash(from)
        |> send_raw(adapter, pid)

      error ->
        error
    end
  end

  defp send_token(
         %{
           from: from,
           to: to,
           amount: amount,
           contract_address: contract_address
         } = attrs,
         adapter,
         pid
       ) do
    with {:ok, encoded_abi_data} <- ABIEncoder.transfer(to, amount),
         {:ok, nonce} <- get_transaction_count(%{address: from}, adapter, pid) do
      gas_limit = Application.get_env(:eth_blockchain, :default_contract_transaction_gas_limit)
      gas_price = get_gas_price_or_default(attrs)

      %__MODULE__{
        gas_limit: gas_limit,
        gas_price: gas_price,
        nonce: int_from_hex(nonce),
        to: from_hex(contract_address),
        data: encoded_abi_data
      }
      |> sign_and_hash(from)
      |> send_raw(adapter, pid)
    else
      error -> error
    end
  end

  defp get_gas_price_or_default(%{gas_price: gas_price}), do: gas_price

  defp get_gas_price_or_default(_attrs) do
    Application.get_env(:eth_blockchain, :default_gas_price)
  end

  defp sign_and_hash(%__MODULE__{} = transaction_data, from) do
    case sign_transaction(transaction_data, from) do
      {:ok, signed_trx} ->
        hashed =
          signed_trx
          |> serialize()
          |> ExRLP.encode()
          |> to_hex()

        {:ok, hashed}

      error ->
        error
    end
  end

  defp send_raw({:ok, transaction_data}, adapter, pid) do
    Adapter.call({:send_raw, transaction_data}, adapter, pid)
  end

  defp send_raw(error, _adapter, _pid), do: error

  defp get_transaction_count(%{address: address}, adapter, pid) do
    Adapter.call({:get_transaction_count, address}, adapter, pid)
  end

  defp sign_transaction(transaction, wallet_address) do
    chain_id = Application.get_env(:eth_blockchain, :chain_id)

    result =
      transaction
      |> transaction_hash(chain_id)
      |> Signature.sign_transaction_hash(wallet_address, chain_id)

    case result do
      {:ok, {v, r, s}} -> {:ok, %{transaction | v: v, r: r, s: s}}
      error -> error
    end
  end

  @doc """
  Serialize, encode and returns a hash of a given transaction
  """
  @spec transaction_hash(__MODULE__.t(), integer()) :: Keccak.keccak_hash()
  def transaction_hash(trx, chain_id) do
    trx
    |> serialize(false)
    |> Kernel.++([encode_unsigned(chain_id), <<>>, <<>>])
    |> ExRLP.encode()
    |> Keccak.kec()
  end

  @doc """
  Encodes a transaction such that it can be RLP-encoded.
  """
  @spec serialize(__MODULE__.t(), bool()) :: ExRLP.t()
  def serialize(trx, include_vrs \\ true) do
    init_or_data =
      case trx.to do
        <<>> -> trx.init
        _ -> trx.data
      end

    base = [
      trx.nonce |> encode_unsigned(),
      trx.gas_price |> encode_unsigned(),
      trx.gas_limit |> encode_unsigned(),
      trx.to,
      trx.value |> encode_unsigned(),
      init_or_data
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
  Decodes a transaction that was previously encoded using `Transaction.serialize/1`.
  """
  @spec deserialize(ExRLP.t()) :: __MODULE__.t()
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

    {init, data} =
      case to do
        <<>> -> {init_or_data, <<>>}
        _ -> {<<>>, init_or_data}
      end

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
