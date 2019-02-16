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

defmodule EWallet.Web.BalanceLoader do
  @moduledoc """
  Module responsible for adding balances to wallets.
  """
  alias EWallet.Web.Paginator
  alias EWallet.BalanceFetcher
  alias EWalletDB.Wallet

  def add_balances(%Paginator{} = paged_wallets) do
    {:ok, wallets} = BalanceFetcher.all(%{"wallets" => paged_wallets.data})
    %{paged_wallets | data: wallets}
  end

  def add_balances(%Wallet{} = wallet) do
    BalanceFetcher.all(%{"wallet" => wallet})
  end

  def add_balances({:ok, wallet}) do
    BalanceFetcher.all(%{"wallet" => wallet})
  end

  def add_balances(error), do: error
end
