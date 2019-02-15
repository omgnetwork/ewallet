# Copyright 2017-2019 OmiseGO Pte Ltd
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

defmodule ExternalLedgerDB.TemporaryAdapter.Token do
  @moduledoc """
  The TempoarayAdapter.Token to be replaced by #693.
  """
  alias ABI.TypeDecoder
  alias Ethereumex.HttpClient

  def fetch(contract_address, _adapter) do
    contract_data = %{
      net_version: get_net_version(),
      contract_address: contract_address,
      total_supply: get_total_supply(contract_address),
      name: get_name(contract_address),
      symbol: get_symbol(contract_address),
      decimals: get_decimals(contract_address)
    }

    {:ok, contract_data}
  end

  defp get_net_version() do
    {:ok, net_version} = HttpClient.net_version()

    net_version
  end

  defp get_total_supply(contract_address) do
    abi_encoded_data =
      "totalSupply()"
      |> ABI.encode([])
      |> Base.encode16(case: :lower)

    {:ok, response_bytes} =
      HttpClient.eth_call(%{
        data: "0x" <> abi_encoded_data,
        to: contract_address
      })

    response_bytes
    |> String.slice(2..-1)
    |> Base.decode16!(case: :lower)
    |> TypeDecoder.decode_raw([{:uint, 256}])
    |> List.first()
  end

  defp get_name(contract_address) do
    abi_encoded_data =
      "name()"
      |> ABI.encode([])
      |> Base.encode16(case: :lower)

    {:ok, response_bytes} =
      HttpClient.eth_call(%{
        data: "0x" <> abi_encoded_data,
        to: contract_address
      })

    response_bytes
    |> String.slice(2..-1)
    |> Base.decode16!(case: :lower)
    |> TypeDecoder.decode_raw([{:tuple, [:string]}])
    |> List.first()
    |> elem(0)
  end

  defp get_symbol(contract_address) do
    abi_encoded_data =
      "symbol()"
      |> ABI.encode([])
      |> Base.encode16(case: :lower)

    {:ok, response_bytes} =
      HttpClient.eth_call(%{
        data: "0x" <> abi_encoded_data,
        to: contract_address
      })

    response_bytes
    |> String.slice(2..-1)
    |> Base.decode16!(case: :lower)
    |> TypeDecoder.decode_raw([{:tuple, [:string]}])
    |> List.first()
    |> elem(0)
  end

  defp get_decimals(contract_address) do
    abi_encoded_data =
      "decimals()"
      |> ABI.encode([])
      |> Base.encode16(case: :lower)

    {:ok, response_bytes} =
      HttpClient.eth_call(%{
        data: "0x" <> abi_encoded_data,
        to: contract_address
      })

    response_bytes
    |> String.slice(2..-1)
    |> Base.decode16!(case: :lower)
    |> TypeDecoder.decode_raw([{:uint, 8}])
    |> List.first()
  end
end
