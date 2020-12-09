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

  alias EthBlockchain.{AdapterServer, ABIEncoder}
  alias ABI.{TypeDecoder, FunctionSelector}

  @allowed_fields ["name", "symbol", "decimals", "totalSupply", "mintingFinished"]

  @doc """
  Attempt to query the value of the field for the given contract address.
  Possible fields are: "name", "symbol", "decimals", "totalSupply", "mintingFinished"
  Returns {:ok, value} if found.
  If the given field is not allowed, returns {:error, :invalid_field}
  If the given field cannot be found in the contract, returns: {:error, :field_not_found}
  """
  @spec get_field(map(), list()) ::
          {atom(), String.t()} | {atom(), atom()} | {atom(), atom(), String.t()}
  def get_field(attrs, opts \\ [])

  def get_field(%{field: field, contract_address: contract_address}, opts)
      when field in @allowed_fields do
    case ABIEncoder.get_field(field) do
      {:ok, encoded_abi_data} ->
        {:get_field, contract_address, to_hex(encoded_abi_data)}
        |> AdapterServer.eth_call(opts)
        |> parse_response(field, opts)

      error ->
        error
    end
  end

  def get_field(_, _), do: {:error, :invalid_field}

  def locked?(attrs, opts \\ []) do
    attrs
    |> Map.put(:field, "mintingFinished")
    |> get_field(opts)
  end

  defp parse_response({:ok, "0x" <> ""}, _field, _opts) do
    {:error, :field_not_found}
  end

  defp parse_response({:ok, "0x" <> data}, "decimals", _opts) do
    [decimals] = decode_abi(data, [{:uint, 256}])
    {:ok, decimals}
  end

  defp parse_response({:ok, "0x" <> data}, "totalSupply", _opts) do
    [supply] = decode_abi(data, [{:uint, 256}])
    {:ok, supply}
  end

  defp parse_response({:ok, "0x" <> data}, "mintingFinished", _opts) do
    [result] = decode_abi(data, [:bool])
    {:ok, result}
  end

  defp parse_response({:ok, "0x" <> data}, _field, _opts) do
    [str] = decode_abi(data, [:string])
    {:ok, str}
  end

  defp parse_response({:error, code}, _field, _opts), do: handle_error(code)

  defp parse_response({:error, code, description}, _field, _opts),
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
