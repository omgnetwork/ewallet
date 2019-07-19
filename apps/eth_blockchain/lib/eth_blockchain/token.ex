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

defmodule EthBlockchain.Token do
  @moduledoc false
  import Utils.Helpers.Encoding
  import EthBlockchain.ErrorHandler

  alias EthBlockchain.{Adapter, ABIEncoder, Transaction}
  alias ABI.{TypeDecoder, TypeEncoder, FunctionSelector}

  @allowed_fields ["name", "symbol", "decimals", "totalSupply"]

  @erc20UUID "3681491a-e8d0-4219-a40a-53d9a47fe64a"

  @erc20MintableUUID "9e0340c0-9aa4-4a01-b280-d400bc2dca73"

  @doc """
  Format and submit an ERC20 contract creation transaction with the given data
  Returns {:ok, tx_hash, contract_address} if success,
  {:error, code} || {:error, code, message} otherwise
  """
  def deploy_erc20(attrs, adapter \\ nil, pid \\ nil)

  def deploy_erc20(%{locked: false} = attrs, adapter, pid) do
    do_deploy(attrs, @erc20MintableUUID, adapter, pid)
  end

  def deploy_erc20(attrs, adapter, pid) do
    do_deploy(attrs, @erc20UUID, adapter, pid)
  end

  defp do_deploy(
         %{
           from: from,
           name: name,
           symbol: symbol,
           decimals: decimals,
           initial_amount: initial_amount
         },
         contract_uuid,
         adapter,
         pid
       ) do
    constructor_attributes =
      [{name, symbol, decimals, initial_amount}]
      |> TypeEncoder.encode(%ABI.FunctionSelector{
        function: nil,
        types: [{:tuple, [:string, :string, {:uint, 8}, {:uint, 256}]}]
      })
      |> Base.encode16(case: :lower)

    contract_binary =
      :eth_blockchain
      |> Application.get_env(:contracts_file_path)
      |> File.read!()
      |> Jason.decode!()
      |> Map.get(contract_uuid)
      |> Map.get("binary")

    data = "0x" <> contract_binary <> constructor_attributes

    %{from: from, contract_data: data}
    |> Transaction.create_contract(adapter, pid)
    |> respond_deploy(contract_uuid)
  end

  defp respond_deploy({:ok, _tx_hash, _contract_address} = t, contract_uuid) do
    Tuple.append(t, contract_uuid)
  end

  defp respond_deploy(error, _contract_uuid), do: error

  @doc """
  Attempt to query the value of the field for the given contract address.
  Possible fields are: "name", "symbol", "decimals", "totalSupply"
  Returns {:ok, value} if found.
  If the given field is not allowed, returns {:error, :invalid_field}
  If the given field cannot be found in the contract, returns: {:error, :field_not_found}
  """
  @spec get_field(map(), atom() | nil, pid() | nil) ::
          {atom(), String.t()} | {atom(), atom()} | {atom(), atom(), String.t()}
  def get_field(attrs, adapter \\ nil, pid \\ nil)

  def get_field(%{field: field, contract_address: contract_address}, adapter, pid)
      when field in @allowed_fields do
    case ABIEncoder.get_field(field) do
      {:ok, encoded_abi_data} ->
        {:get_field, contract_address, to_hex(encoded_abi_data)}
        |> Adapter.call(adapter, pid)
        |> parse_response(field, adapter, pid)

      error ->
        error
    end
  end

  def get_field(_, _, _), do: {:error, :invalid_field}

  defp parse_response({:ok, "0x" <> ""}, _field, _adapter, _pid) do
    {:error, :field_not_found}
  end

  defp parse_response({:ok, "0x" <> data}, "decimals", _adapter, _pid) do
    [decimals] = decode_abi(data, [{:uint, 256}])
    {:ok, decimals}
  end

  defp parse_response({:ok, "0x" <> data}, "totalSupply", _adapter, _pid) do
    [supply] = decode_abi(data, [{:uint, 256}])
    {:ok, supply}
  end

  defp parse_response({:ok, "0x" <> data}, _field, _adapter, _pid) do
    [{str}] = decode_abi(data, [{:tuple, [:string]}])
    {:ok, str}
  end

  defp parse_response({:error, code}, _field, _adapter, _pid), do: handle_error(code)

  defp parse_response({:error, code, description}, _field, _adapter, _pid),
    do: handle_error(code, description)

  defp decode_abi(data, types) do
    data
    |> Base.decode16!(case: :lower)
    |> TypeDecoder.decode(%FunctionSelector{
      function: nil,
      types: types
    })
  end
end
