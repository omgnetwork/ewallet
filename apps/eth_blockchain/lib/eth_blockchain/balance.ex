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

defmodule EthBlockchain.Balance do
  @moduledoc false
  import Utils.Helpers.Encoding

  alias EthBlockchain.{Adapter, ABIEncoder}

  @doc """
  Retrieve the balance of all given `contract_addresses` for the provided wallet `address`.
  Ether is represented with `0x0000000000000000000000000000000000000000` as contract address.
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
  def get(attrs, opts \\ [])

  def get(%{block: _} = attrs, opts) do
    do_get(attrs, opts)
  end

  def get(attrs, opts) do
    attrs
    |> Map.put(:block, "latest")
    |> do_get(opts)
  end

  defp do_get(
         %{address: address, contract_addresses: contract_addresses, block: block},
         opts
       ) do
    case ABIEncoder.balance_of(address) do
      {:ok, encoded_abi_data} ->
        {:get_balances, address, contract_addresses, to_hex(encoded_abi_data), block}
        |> Adapter.eth_call(opts)
        |> parse_response()
        |> respond(contract_addresses)

      error ->
        error
    end
  end

  defp parse_response({:ok, data}) when is_list(data) do
    balances = Enum.map(data, fn hex_balance -> parse_hex_balance(hex_balance) end)
    {:ok, balances}
  end

  defp parse_response({:ok, data}), do: {:ok, parse_hex_balance(data)}

  defp parse_response(error), do: error

  # function `balanceOf(address)` not found in contract
  defp parse_hex_balance("0x"), do: nil

  # function `balanceOf(address)` found in contract
  defp parse_hex_balance(balance), do: int_from_hex(balance)

  defp respond({:ok, balances}, addresses) do
    response =
      [addresses, balances]
      |> Enum.zip()
      |> Enum.into(%{})

    {:ok, response}
  end

  defp respond({:error, _error} = error, _addresses), do: error
end
