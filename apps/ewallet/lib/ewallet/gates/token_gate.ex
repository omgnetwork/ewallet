# Copyright 2018-2019 OmiseGO Pte Ltd
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

defmodule EWallet.TokenGate do
  @moduledoc false

  alias EthBlockchain.{Balance, Token}

  @doc """
  Check the if the given contract implements the required read only ERC20 functions.
  This will check 2 required functions:
  - totalSupply()
  - balanceOf(address)
  And 3 optional functions:
  - name()
  - symbol()
  - decimals()
  Will return {:ok, info} if the 2 required function are present in the contract definition.
  Where info is a map that contains `total_supply` and optionally `name`, `symbol` and `decimals`
  if found.
  Will return {:error, :token_not_erc20} if the contract does not implement the required functions
  Will return {:error, :error_code} or {:error, :error_code, message} if an error occured.
  """
  @spec verify_erc20_capabilities(String.t()) ::
          {:ok, map()} | {:error, atom()} | {:error, atom(), String.t()}
  def verify_erc20_capabilities(contract_address) do
    with {:ok, mandatory_info} <- verify_mandatory(contract_address),
         {:ok, optional_info} <- verify_optional(contract_address) do
      {:ok, Map.merge(mandatory_info, optional_info)}
    else
      error -> error
    end
  end

  defp verify_optional(contract_address) do
    with {:ok, name} <- Token.get_field(%{field: "name", contract_address: contract_address}),
         {:ok, symbol} <- Token.get_field(%{field: "symbol", contract_address: contract_address}),
         {:ok, decimals} <-
           Token.get_field(%{field: "decimals", contract_address: contract_address}) do
      {:ok, %{name: name, symbol: symbol, decimals: decimals}}
    else
      {:error, :field_not_found} -> {:ok, %{}}
      error -> error
    end
  end

  defp verify_mandatory(contract_address) do
    with {:ok, total_supply} <-
           Token.get_field(%{field: "totalSupply", contract_address: contract_address}),
         {:ok, %{^contract_address => balance}} <-
           Balance.get(%{address: contract_address, contract_addresses: [contract_address]}),
         true <- !is_nil(balance) || {:error, :token_not_erc20} do
      {:ok, %{total_supply: total_supply}}
    else
      {:error, :token_not_erc20} = error -> error
      {:error, :field_not_found} -> {:error, :token_not_erc20}
      error -> error
    end
  end
end
