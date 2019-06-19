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
  @moduledoc """

  """

  alias EthBlockchain.{Balance, Token}

  @doc """

  """
  @spec verify_erc20_capabilities(String.t()) :: {:ok, map()} | {:error, atom()}
  def verify_erc20_capabilities(contract_address) do
    with {:ok, mandatory_info} <- verify_mandatory(contract_address),
         {:ok, optional_info} <- verify_optional(contract_address) do
      {:ok, Map.merge(mandatory_info, optional_info)}
    else
      error -> error
    end
  end

  def verify_optional(contract_address) do
    with {:ok, name} <- Token.get_field({"name", contract_address}),
         {:ok, symbol} <- Token.get_field({"symbol", contract_address}),
         {:ok, decimals} <- Token.get_field({"decimals", contract_address}) do
      {:ok, %{name: name, symbol: symbol, decimals: decimals}}
    else
      {:error, :field_not_found} -> {:ok, %{}}
      error -> error
    end
  end

  def verify_mandatory(contract_address) do
    with {:ok, total_supply} <- Token.get_field({"totalSupply", contract_address}),
         {:ok, %{^contract_address => balance}} <-
           Balance.get({contract_address, contract_address}),
         true <- !is_nil(balance) || {:error, :not_erc20} do
      {:ok, %{total_supply: total_supply}}
    else
      {:error, :not_erc20} = error -> error
      {:error, :field_not_found} -> {:error, :not_erc20}
      error -> error
    end
  end
end
