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

defmodule ExternalLedgerDB.TemporaryAdapter do
  @moduledoc """
  The TempoarayAdapter to be replaced by #693.
  """
  alias ABI.TypeDecoder
  alias Ethereumex.HttpClient

  @ethereum "ethereum"
  @omg_network "omg_network"
  @adapters [@ethereum, @omg_network]

  def valid_adapter?(adapter) do
    adapter in @adapters
  end

  def fetch_contract(contract_address, _adapter) do
    abi_encoded_data =
      "totalSupply()"
      |> ABI.encode([])
      |> Base.encode16(case: :lower)

    {:ok, total_supply_bytes} =
      %{
        data: "0x" <> abi_encoded_data,
        to: contract_address
      }
      |> HttpClient.eth_call()
      |> String.slice(2..-1)
      |> Base.decode16!(case: :lower)
      |> TypeDecoder.decode_raw([{:uint, 256}])
      |> List.first

    contract_data = %{
      total_supply: total_supply
    }

    {:ok, contract_data}
  end
end
