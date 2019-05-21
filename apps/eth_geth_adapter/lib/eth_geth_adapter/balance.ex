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

defmodule EthGethAdapter.Balance do
  @moduledoc false
  import Utils.Helpers.Encoding

  alias Ethereumex.HttpClient, as: Client

  @doc """
  Retrieve the balance of all given `contract_addresses` for the provided wallet `address`.
  The `0x0000000000000000000000000000000000000000` address is used to represent Ether.
  Any other given contract address will have their balance retrived on the corresponding
  smart contract.

  Returns a tuple of
  ```
  {
    :ok,
    %{
      "contract_address_1" => integer_balance_1,
      "contract_address_2" => integer_balance_2
    }
  }
  ```
  if successful or {:error, error_code} if failed.
  """
  def get(address, contract_address, encoded_abi_data, block \\ "latest")

  def get(address, contract_addresses, encoded_abi_data, block)
      when is_list(contract_addresses) do
    contract_addresses
    |> Enum.map(fn contract_address ->
      build_request!(contract_address, address, encoded_abi_data, block)
    end)
    |> request()
    |> parse_response()
    |> respond(contract_addresses)
  end

  def get(address, contract_address, encoded_abi_data, block) do
    get(address, [contract_address], encoded_abi_data, block)
  end

  # Batch request builders

  defp build_request!("0x0000000000000000000000000000000000000000", address, _, block) do
    {:eth_get_balance, [address, block]}
  end

  defp build_request!(contract_address, _address, encoded_abi_data, block)
       when byte_size(contract_address) == 42 do
    {:eth_call,
     [
       %{
         data: encoded_abi_data,
         to: contract_address
       },
       block
     ]}
  end

  defp build_request!(contract_address, _address, _encoded_abi_data, _block) do
    raise ArgumentError, "#{contract_address} is not a valid contract address"
  end

  defp request([]), do: {:ok, []}

  defp request(data), do: Client.batch_request(data)

  # Response parsers

  defp parse_response({:ok, data}) when is_list(data) do
    balances = Enum.map(data, fn hex_balance -> int_from_hex(hex_balance) end)
    {:ok, balances}
  end

  defp parse_response({:ok, data}), do: {:ok, int_from_hex(data)}

  defp parse_response({:error, data}), do: {:error, data}

  # Formatters

  defp respond({:ok, balances}, addresses) do
    response =
      [addresses, balances]
      |> Enum.zip()
      |> Enum.into(%{})

    {:ok, response}
  end

  defp respond({:error, _error} = error, _addresses), do: error
end
