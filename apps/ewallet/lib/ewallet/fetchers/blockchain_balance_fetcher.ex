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

defmodule EWallet.BlockchainBalanceFetcher do
  @moduledoc """
  Handles the retrieval and formatting of balances from the local ledger.
  """

  @spec all(%EWalletDB.BlockchainWallet{}, [%EWalletDB.Token{}]) ::
          {:ok, %EWalletDB.BlockchainWallet{}} | {:error, atom()}
  @doc """
  Prepare the list of balances for specified tokens and turn them into a suitable format for
  EWalletAPI using a blockchain wallet and a list of tokens.
  """
  def all(wallet, tokens) do
    {:ok, query_and_add_balances(wallet, tokens)}
  end

  defp query_and_add_balances(wallet, tokens) do
    adapter = Application.get_env(:ewallet, :blockchain_adapter)

    wallet.address
    |> adapter.get_balances(filtered_token_addresses(tokens))
    |> process_response(tokens)
  end

  defp filtered_token_addresses(tokens) do
    tokens
    |> Enum.map(fn token -> token.blockchain_address end)
    |> Enum.reject(&is_nil/1)
  end

  defp process_response({:ok, data}, tokens) do
    map_tokens(tokens, data)
  end

  defp map_tokens(tokens, amounts) do
    Enum.map(tokens, fn token ->
      %{
        token: token,
        amount: amounts[token.blockchain_address] || 0
      }
    end)
  end
end
