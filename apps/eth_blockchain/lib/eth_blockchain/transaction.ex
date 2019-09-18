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
  alias EthBlockchain.{AdapterServer, ABIEncoder, GasHelper, Helper, Nonce, NonceRegistry}

  @eth Helper.default_address()

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
  @spec send(map(), list) ::
          {atom(), String.t()} | {atom(), atom()} | {atom(), atom(), String.t()}
  def send(attrs, opts \\ [])

  # Send ETH
  def send(%{contract_address: @eth} = attrs, opts) do
    send_eth(attrs, opts)
  end

  # Send ERC20
  def send(%{contract_address: _} = attrs, opts) do
    send_token(attrs, opts)
  end

  # Send eth by default
  def send(attrs, opts) do
    send_eth(attrs, opts)
  end

  defp send_eth(
         %{
           from: from,
           to: to,
           amount: amount
         } = attrs,
         opts
       ) do
    with {:ok, meta} <- get_transaction_meta(attrs, :eth_transaction, opts),
         {:ok, wallet} <- get_wallet(attrs) do
      %__MODULE__{
        to: from_hex(to),
        value: amount
      }
      |> prepare_and_send(meta, wallet || from, opts)
      |> respond(from, opts)
    end
  end

  defp send_token(
         %{
           from: from,
           to: to,
           amount: amount,
           contract_address: contract_address
         } = attrs,
         opts
       ) do
    with {:ok, meta} <- get_transaction_meta(attrs, :contract_transaction, opts),
         {:ok, wallet} <- get_wallet(attrs),
         {:ok, encoded_abi_data} <- ABIEncoder.transfer(to, amount) do
      %__MODULE__{
        to: from_hex(contract_address),
        data: encoded_abi_data
      }
      |> prepare_and_send(meta, wallet || from, opts)
      |> respond(from, opts)
    end
  end

  @doc """
  Submit a contract creation transaction with the given data
  Returns {:ok, tx_hash, contract_address} if success,
  {:error, code} || {:error, code, message} otherwise
  """
  def create_contract(%{wallet: _}) do
    raise ArgumentError, message: "Create a contract with a child key is not supported."
  end

  def create_contract(%{from: from, contract_data: init} = attrs, opts \\ []) do
    with {:ok, %{nonce: nonce} = meta} <-
           get_transaction_meta(attrs, :contract_creation, opts),
         contract_address <- get_contract_address(nonce, from) do
      %__MODULE__{init: from_hex(init)}
      |> prepare_and_send(meta, from, opts)
      |> append_contract_address(contract_address)
      |> respond(from, opts)
    end
  end

  @doc """
  Submit a deposit eth transaction to the specified root chain contract
  """
  def deposit_eth(%{wallet: _}) do
    raise ArgumentError, message: "Deposit ETH with a child key is not supported."
  end

  def deposit_eth(
        %{
          tx_bytes: tx_bytes,
          from: from,
          amount: amount,
          root_chain_contract: root_chain_contract
        } = attrs,
        opts \\ []
      ) do
    with {:ok, meta} <- get_transaction_meta(attrs, :child_chain_deposit_eth, opts),
         {:ok, encoded_abi_data} <- ABIEncoder.child_chain_eth_deposit(tx_bytes) do
      %__MODULE__{
        to: from_hex(root_chain_contract),
        data: encoded_abi_data,
        value: amount
      }
      |> prepare_and_send(meta, from, opts)
      |> respond(from, opts)
    end
  end

  @doc """
  Submit a deposit transaction of an ERC20 token to the specified childchain contract
  """
  def deposit_erc20(%{wallet: _}) do
    raise ArgumentError, message: "Deposit an ERC-20 with a child key is not supported."
  end

  def deposit_erc20(
        %{
          tx_bytes: tx_bytes,
          from: from,
          root_chain_contract: root_chain_contract
        } = attrs,
        opts \\ []
      ) do
    with {:ok, meta} <- get_transaction_meta(attrs, :child_chain_deposit_token, opts),
         {:ok, encoded_abi_data} <- ABIEncoder.child_chain_erc20_deposit(tx_bytes) do
      %__MODULE__{
        to: from_hex(root_chain_contract),
        data: encoded_abi_data
      }
      |> prepare_and_send(meta, from, opts)
      |> respond(from, opts)
    end
  end

  @doc """
  Submit an approve ERC20 transaction
  """
  def approve_erc20(%{wallet: _}) do
    raise ArgumentError, message: "Approve an ERC-20 with a child key is not supported."
  end

  def approve_erc20(
        %{
          from: from,
          to: to,
          amount: amount,
          contract_address: contract_address
        } = attrs,
        opts \\ []
      ) do
    with {:ok, meta} <- get_transaction_meta(attrs, :contract_transaction, opts),
         {:ok, encoded_abi_data} <- ABIEncoder.approve(to, amount) do
      %__MODULE__{
        to: from_hex(contract_address),
        data: encoded_abi_data
      }
      |> prepare_and_send(meta, from, opts)
      |> respond(from, opts)
    end
  end

  @doc """
  Submit a mint ERC20 transaction
  """
  def mint_erc20(%{wallet: _}) do
    raise ArgumentError, message: "Mint an ERC-20 with a child key is not supported."
  end

  def mint_erc20(
        %{
          from: address,
          amount: amount,
          contract_address: contract_address
        } = attrs,
        opts \\ []
      ) do
    with {:ok, meta} <- get_transaction_meta(attrs, :contract_transaction, opts),
         {:ok, encoded_abi_data} <- ABIEncoder.mint(address, amount) do
      %__MODULE__{
        to: from_hex(contract_address),
        data: encoded_abi_data
      }
      |> prepare_and_send(meta, address, opts)
      |> respond(address, opts)
    end
  end

  @doc """
  Submit a lock ERC20 transaction
  """
  def lock_erc20(%{wallet: _}) do
    raise ArgumentError, message: "Lock an ERC-20 with a child key is not supported."
  end

  def lock_erc20(
        %{
          from: address,
          contract_address: contract_address
        } = attrs,
        opts \\ []
      ) do
    with {:ok, meta} <- get_transaction_meta(attrs, :contract_transaction, opts),
         {:ok, encoded_abi_data} <- ABIEncoder.finish_minting() do
      %__MODULE__{
        to: from_hex(contract_address),
        data: encoded_abi_data
      }
      |> prepare_and_send(meta, address, opts)
      |> respond(address, opts)
    end
  end

  defp get_transaction_meta(%{from: from} = attrs, gas_limit_type, opts) do
    with {:ok, nonce_handler_pid} <-
           NonceRegistry.lookup(from, opts[:eth_node_adapter], opts[:eth_node_adapter_pid]),
         {:ok, nonce} <- Nonce.next_nonce(nonce_handler_pid) do
      gas_limit = GasHelper.get_gas_limit_or_default(gas_limit_type, attrs)
      gas_price = GasHelper.get_gas_price_or_default(attrs)

      {:ok, %{gas_price: gas_price, gas_limit: gas_limit, nonce: nonce}}
    end
  end

  defp get_wallet(%{
         wallet:
           %{
             derivation_path: _,
             wallet_id: _,
             account_ref: _,
             deposit_ref: _
           } = wallet
       }) do
    {:ok, wallet}
  end

  defp get_wallet(%{wallet: wallet}) do
    raise ArgumentError,
      message: "Invalid wallet data for transaction signing. Got: #{inspect(wallet)}."
  end

  defp get_wallet(_), do: {:ok, nil}

  defp get_contract_address(nonce, sender) do
    "0x" <> <<_::bytes-size(24)>> <> contract_address =
      [from_hex(sender), encode_unsigned(nonce)]
      |> ExRLP.encode()
      |> Keccak.kec()
      |> to_hex()

    "0x" <> contract_address
  end

  defp prepare_and_send(%__MODULE__{} = transaction, meta, from, opts) do
    transaction
    |> Map.merge(meta)
    |> sign_and_hash(from)
    |> send_raw(opts)
  end

  defp sign_and_hash(%__MODULE__{} = transaction_data, from) do
    with {:ok, signed_trx} <- sign_transaction(transaction_data, from) do
      hashed =
        signed_trx
        |> serialize()
        |> ExRLP.encode()
        |> to_hex()

      {:ok, hashed}
    end
  end

  defp send_raw({:ok, transaction_data}, opts) do
    AdapterServer.eth_call({:send_raw, transaction_data}, opts)
  end

  defp send_raw(error, _opts), do: error

  defp sign_transaction(transaction, address) when is_binary(address) do
    chain_id = Application.get_env(:eth_blockchain, :chain_id)

    result =
      transaction
      |> transaction_hash(chain_id)
      |> Signature.sign_transaction_hash(address, chain_id)

    case result do
      {:ok, {v, r, s}} -> {:ok, %{transaction | v: v, r: r, s: s}}
      error -> error
    end
  end

  defp sign_transaction(transaction, %{
         wallet_id: wallet_id,
         derivation_path: derivation_path,
         account_ref: account_ref,
         deposit_ref: deposit_ref
       }) do
    chain_id = Application.get_env(:eth_blockchain, :chain_id)

    result =
      transaction
      |> transaction_hash(chain_id)
      |> Signature.sign_transaction_hash(
        wallet_id,
        derivation_path,
        account_ref,
        deposit_ref,
        chain_id
      )

    case result do
      {:ok, {v, r, s}} -> {:ok, %{transaction | v: v, r: r, s: s}}
      error -> error
    end
  end

  defp append_contract_address({:ok, _} = t, contract_address) do
    Tuple.append(t, contract_address)
  end

  defp append_contract_address(error, _), do: error

  # The nonce used in the transaction was too low, meaning that a transaction with a higher
  # nonce was already mined.
  # We force the refresh of the nonce generator which will reset the nonce to the current
  # transaction count. This way we avoid having failed transaction until we reach the
  # correct nonce
  defp respond({:error, _, [error_message: "nonce too low"]} = error, from, opts) do
    with {:ok, nonce_handler_pid} <-
           NonceRegistry.lookup(from, opts[:eth_node_adapter], opts[:eth_node_adapter_pid]),
         {:ok, _nonce} <- Nonce.force_refresh(nonce_handler_pid) do
      error
    end
  end

  defp respond(response, _from, _opts), do: response

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
