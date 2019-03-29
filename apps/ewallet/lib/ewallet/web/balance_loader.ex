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

defmodule EWallet.Web.BalanceLoader do
  @moduledoc """
  Module responsible for adding balances to wallets.
  """
  alias EWallet.Web.Paginator
  alias EWallet.BalanceFetcher
  alias EWalletDB.{Wallet, Repo}
  import Ecto.Query

  def add_balances_to_wallets_intersect(paginator, query) do
    uuids = Enum.map(paginator.data, fn wallet -> wallet.uuid end)

    view_balance_wallets =
      query
      |> where([w], w.uuid in ^uuids)
      |> Repo.all()

    wallets_with_balances = add_balances(view_balance_wallets)

    wallets =
      Enum.map(paginator.data, fn wallet ->
        case Enum.find(wallets_with_balances, fn wallet_with_balances ->
               wallet_with_balances.uuid == wallet.uuid
             end) do
          nil ->
            wallet

          wallet_with_balances ->
            Map.put(wallet, :balances, wallet_with_balances.balances)
        end
      end)

    %{paginator | data: wallets}
  end

  def add_balances(%Paginator{} = paged_wallets) do
    {:ok, wallets} = BalanceFetcher.all(%{"wallets" => paged_wallets.data})
    %{paged_wallets | data: wallets}
  end

  def add_balances(wallets) when is_list(wallets) do
    {:ok, wallets} = BalanceFetcher.all(%{"wallets" => wallets})
    wallets
  end

  def add_balances(%Wallet{} = wallet) do
    BalanceFetcher.all(%{"wallet" => wallet})
  end

  def add_balances({:ok, wallet}) do
    BalanceFetcher.all(%{"wallet" => wallet})
  end

  def add_balances(error), do: error

  def add_balances(%Wallet{} = wallet, tokens) do
    BalanceFetcher.all(%{"wallet" => wallet, "tokens" => tokens})
  end
end
