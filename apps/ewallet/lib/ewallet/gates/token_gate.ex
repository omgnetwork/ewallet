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
  Validate that the `decimals` and `symbol` of the token are the same as
  the ones defined in the erc20 contract. If the contract does not implement
  these fields, we rely on the token's field values.
  Returns {:ok, status} where `status` is the blockchain status of the token.
  The status is "confirmed" if the hot wallet balance is positive, or "pending" otherwise.
  """
  def validate_erc20_readiness(contract_address, token) do
    with {:ok, erc20_attrs} <- get_erc20_capabilities(contract_address),
         :ok <- validate_decimals(erc20_attrs, token),
         :ok <- validate_symbol(erc20_attrs, token) do
      {:ok, get_blockchain_status(erc20_attrs)}
    else
      :error -> {:error, :token_not_matching_contract_info}
      error -> error
    end
  end

  defp validate_decimals(%{decimals: value}, token) do
    case value == :math.log10(token.subunit_to_unit) do
      true -> :ok
      false -> :error
    end
  end

  defp validate_decimals(_, _), do: :ok

  defp validate_symbol(%{symbol: value}, %{symbol: value}), do: :ok

  defp validate_symbol(%{symbol: _value}, %{symbol: _diff_value}), do: :error

  defp validate_symbol(_, _), do: :ok

  def get_blockchain_status(%{hot_wallet_balance: balance}) when balance > 0 do
    EWalletDB.Token.blockchain_status_confirmed()
  end

  def get_blockchain_status(%{hot_wallet_balance: _balance}) do
    EWalletDB.Token.blockchain_status_pending()
  end

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
  @spec get_erc20_capabilities(String.t()) ::
          {:ok, map()} | {:error, atom()} | {:error, atom(), String.t()}
  def get_erc20_capabilities(contract_address) do
    with {:ok, mandatory_info} <- get_mandatory(contract_address),
         {:ok, optional_info} <- get_optional(contract_address) do
      {:ok, Map.merge(mandatory_info, optional_info)}
    else
      error -> error
    end
  end

  defp get_optional(contract_address) do
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

  # TODO: get balance of current hot wallet
  defp get_mandatory(contract_address) do
    with {:ok, total_supply} <-
           Token.get_field(%{field: "totalSupply", contract_address: contract_address}),
         {:ok, %{^contract_address => balance}} <-
           Balance.get(%{address: contract_address, contract_addresses: [contract_address]}),
         true <- !is_nil(balance) || {:error, :token_not_erc20} do
      {:ok, %{total_supply: total_supply, hot_wallet_balance: balance}}
    else
      {:error, :token_not_erc20} = error -> error
      {:error, :field_not_found} -> {:error, :token_not_erc20}
      error -> error
    end
  end
end
