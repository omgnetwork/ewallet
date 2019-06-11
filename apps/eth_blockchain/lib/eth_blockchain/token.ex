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
  alias EthBlockchain.Adapter

  @allowed_fields ["name", "symbol", "decimals", "version"]

  @doc """

  """
  def get({field, contract_address}, adapter \\ nil, pid \\ nil) do
    # check if field is allowed
    case EthBlockchain.ABI.get_field(field) do
      {:ok, encoded_abi_data} ->
        Adapter.call(
          adapter,
          {:get_field, contract_address, to_hex(encoded_abi_data)},
          pid
        )
        |> parse_response(field)

      error ->
        error
    end
  end

  def parse_response({:ok, "0x" <> ""}, _), do: {:error, :name_not_found}

  def parse_response({:ok, "0x" <> data}, "decimals") do
    [decimals] =
      data
      |> Base.decode16!(case: :lower)
      |> ABI.TypeDecoder.decode(
          %ABI.FunctionSelector{
            function: nil,
            types: [
              {:uint, 256}
            ]
          }
        )

    decimals
  end

  def parse_response({:ok, "0x" <> data}, _) do
    [{str}] =
      data
      |> Base.decode16!(case: :lower)
      |> ABI.TypeDecoder.decode(
          %ABI.FunctionSelector{
            function: nil,
            types: [
              {:tuple, [:string]}
            ]
          }
        )

    str
  end

  def parse_response(error), do: error
end
