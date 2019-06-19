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

  alias EthBlockchain.{Adapter, ABIEncoder}
  alias ABI.{TypeDecoder, FunctionSelector}

  @allowed_fields ["name", "symbol", "decimals"]

  @doc """
  Attempt to query the value of the field for the given contract address.
  Possible fields are: "name", "symbol", "decimals"
  Returns the value of the field if found.
  If the given field is not allowed, returns {:error, :invalid_field}
  If the given field cannot be found in the contract, returns: {:error, :`field`_not_found}
  where `field` is the requested field.
  """
  def get(params, adapter \\ nil, pid \\ nil)

  def get({field, contract_address}, adapter, pid) when field in @allowed_fields do
    case ABIEncoder.get_field(field) do
      {:ok, encoded_abi_data} ->
        adapter
        |> Adapter.call(
          {:get_field, contract_address, to_hex(encoded_abi_data)},
          pid
        )
        |> parse_response(field)

      error ->
        error
    end
  end

  def get(_, _, _), do: {:error, :invalid_field}

  defp parse_response({:ok, "0x" <> ""}, field) do
    {:error, String.to_atom("#{field}_not_found")}
  end

  defp parse_response({:ok, "0x" <> data}, "decimals") do
    [decimals] = decode_abi(data, [{:uint, 256}])
    decimals
  end

  defp parse_response({:ok, "0x" <> data}, _field) do
    [{str}] = decode_abi(data, [{:tuple, [:string]}])
    str
  end

  defp parse_response(error, _field), do: error

  defp decode_abi(data, types) do
    data
    |> Base.decode16!(case: :lower)
    |> TypeDecoder.decode(%FunctionSelector{
      function: nil,
      types: types
    })
  end
end
