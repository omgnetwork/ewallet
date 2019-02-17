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

defmodule LocalLedger.Wallet do
  @moduledoc """
  This module is an interface to the LocalLedgerDB schema (Balance, CachedBalance
  and Entry) and contains the logic needed to lock a list of addresses.
  """
  alias LocalLedger.CachedBalance
  alias LocalLedgerDB.{Repo, Wallet}

  @doc """
  Calculate and returns the current wallets for each token associated
  with the given address or addresses.
  """
  def all_balances(addresses) when is_list(addresses) do
    case Wallet.all(addresses) do
      nil -> {:ok, %{}}
      wallets -> CachedBalance.all(wallets)
    end
  end

  def all_balances(address) do
    case Wallet.get(address) do
      nil -> {:ok, %{}}
      wallet -> CachedBalance.all(wallet)
    end
  end

  @doc """
  Calculate and returns the current balance for the specified token
  associated with the given address or addresses.
  """
  def get_balance(token_id, addresses) when is_list(addresses) do
    case Wallet.all(addresses) do
      nil -> {:ok, %{}}
      wallets -> CachedBalance.get(wallets, token_id)
    end
  end

  def get_balance(token_id, address) do
    case Wallet.get(address) do
      nil -> {:ok, %{}}
      wallet -> CachedBalance.get(wallet, token_id)
    end
  end

  @doc """
  Run the given function in a safe environment by locking all the matching
  wallets.
  """
  def lock(addresses, fun) do
    Repo.transaction(fn ->
      Wallet.lock(addresses)
      res = fun.()
      Wallet.touch(addresses)
      res
    end)
  end
end
