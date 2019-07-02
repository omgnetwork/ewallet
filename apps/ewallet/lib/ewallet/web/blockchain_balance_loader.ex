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

defmodule EWallet.Web.BlockchainBalanceLoader do
  @moduledoc """
  Module responsible for adding balances to wallets.
  """
  alias EWallet.BlockchainBalanceFetcher
  alias EWalletDB.{BlockchainWallet, Token}

  @spec balances(String.t(), [%Token{}]) :: {:ok, Map.t()}
  def balances(address, tokens) do
    BlockchainBalanceFetcher.all(address, tokens)
  end

  @spec wallet_balances([%BlockchainWallet{}], [%Token{}]) :: {:ok, [Map.t()]}
  def wallet_balances(wallets, tokens) when is_list(wallets) do
    addresses = Enum.map(wallets, fn wallet -> wallet.address end)

    case BlockchainBalanceFetcher.all(addresses, tokens) do
      {:ok, wallets_balances} ->
        {:ok, populate_wallet_balances(wallets, wallets_balances)}

      err ->
        err
    end
  end

  @spec wallet_balances(%BlockchainWallet{}, [%Token{}]) :: {:ok, Map.t()}
  def wallet_balances(wallet, tokens) do
    case wallet_balances([wallet], tokens) do
      {:ok, [wallet_balances]} ->
        {:ok, wallet_balances}

      err ->
        err
    end
  end

  defp populate_wallet_balances(wallets, wallets_balances) when is_list(wallets) do
    wallets
    |> Enum.zip(wallets_balances)
    |> Enum.map(&populate_wallet_balances/1)
  end

  defp populate_wallet_balances({wallet, wallet_balances}) do
    Map.put(wallet, :balances, wallet_balances)
  end
end
