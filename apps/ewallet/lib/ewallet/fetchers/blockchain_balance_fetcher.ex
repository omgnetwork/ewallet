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
  Handles the retrieval and formatting of balances from the blockchain.
  """

  alias EthBlockchain.Balance

  @doc """
  Prepare the list of balances for specified tokens and turn them into a suitable format for
  EWalletAPI using a blockchain wallet address and a list of tokens.
  """
  @spec all(String.t() | [String.t()], [%EWalletDB.Token{}]) ::
          {:ok, [%EWalletDB.BlockchainWallet{}]} | {:error, atom()}
  def all(address_or_addresses, tokens) do
    case do_all(address_or_addresses, tokens) do
      {:error, error} ->
        {:error, :blockchain_adapter_error, error: inspect(error)}

      data ->
        {:ok, data}
    end
  end

  defp do_all(wallet_addresses, tokens) when is_list(wallet_addresses),
    do: do_all([], wallet_addresses, tokens)

  defp do_all(wallet_address, tokens),
    do: hd(do_all([], [wallet_address], tokens))

  defp do_all(balances_for_wallets, [wallet_address | wallet_addresses], tokens) do
    case query_and_add_balances(wallet_address, tokens) do
      {:error, error} ->
        {:error, error}

      balances_for_wallet ->
        do_all([balances_for_wallet | balances_for_wallets], wallet_addresses, tokens)
    end
  end

  defp do_all(balances_for_wallets, [], _),
    do: Enum.reverse(balances_for_wallets)

  defp query_and_add_balances(wallet_address, tokens) do
    token_addresses = Enum.map(tokens, fn token -> token.blockchain_address end)

    %{address: wallet_address, contract_addresses: token_addresses}
    |> Balance.get()
    |> process_response(tokens)
  end

  defp process_response({:ok, data}, tokens) do
    map_tokens(tokens, data)
  end

  defp process_response(error, _tokens), do: error

  defp map_tokens(tokens, amounts) do
    Enum.map(tokens, fn token ->
      %{
        token: token,
        amount: amounts[token.blockchain_address] || 0
      }
    end)
  end
end
