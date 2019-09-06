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

defmodule LocalLedger.CachedBalance do
  @moduledoc """
  This module is an interface to the abstract balances stored in DB. It is responsible for caching
  balances and serves as an interface to retrieve the current balances (which will either be
  loaded from a cached balance or computed - or both).
  """
  alias LocalLedgerDB.{CachedBalance, Entry, Wallet}

  @doc """
  Caches all the wallets balances using a batch stream mechanism for retrieval (1000 at a time). This
  is meant to be used in some kind of schedulers, but can also be ran manually.
  """
  @spec cache_all() :: :ok
  def cache_all do
    strategy = Application.get_env(:local_ledger, :balance_caching_strategy)

    Wallet.stream_all(fn wallet ->
      {:ok, calculate_with_strategy(strategy, wallet)}
    end)
  end

  @doc """
  Deletes the cache since a specific point in time.

  The given datetime also gets included in the deletion.
  """
  @spec delete_since(%Wallet{} | [%Wallet{}], NaiveDateTime.t()) :: {:ok, num_deleted :: integer()}
  def delete_since(wallet_or_wallets, computed_at) do
    wallet_or_wallets
    |> List.wrap()
    |> Enum.map(fn w -> w.address end)
    |> CachedBalance.delete_since(computed_at)
  end

  @doc """
  Gets all the balances for the given wallet or wallets.
  """
  @spec all(%Wallet{} | [%Wallet{}]) :: {:ok, map()}
  def all(wallet_or_wallets, attrs \\ %{}) do
    balances =
      wallet_or_wallets
      |> List.wrap()
      |> get_balances(attrs)

    {:ok, balances}
  end

  @doc """
  Gets the balance for the specified token (token_id) and
  the given wallet.
  """
  @spec get(%Wallet{} | [%Wallet{}], String.t()) :: {:ok, map()}
  def get(wallet_or_wallets, token_id) do
    balances =
      wallet_or_wallets
      |> List.wrap()
      |> get_balances()
      |> Enum.into(%{}, fn {address, amounts} ->
        {address, %{token_id => amounts[token_id] || 0}}
      end)

    {:ok, balances}
  end

  #
  # Private functions for figuring out the latest balances
  # from existing cached balances plus uncached transactions.
  #

  defp get_balances(wallets, attrs \\ %{}) do
    wallets
    |> Enum.map(fn wallet -> wallet.address end)
    |> CachedBalance.all()
    |> calculate_all_amounts(wallets, attrs)
  end

  defp calculate_all_amounts(computed_balances, wallets, attrs) do
    computed_balances =
      Enum.into(computed_balances, %{}, fn balance ->
        {balance.wallet_address, balance}
      end)

    Enum.into(wallets, %{}, fn wallet ->
      attrs = Map.put(attrs, "computed_balance", computed_balances[wallet.address])
      {wallet.address, calculate_amounts(wallet, attrs)}
    end)
  end

  defp calculate_amounts(wallet, %{"computed_balance" => nil, "tokens" => tokens}),
    do: calculate_from_beginning_and_insert(wallet, tokens)

  defp calculate_amounts(wallet, %{"computed_balance" => nil}),
    do: calculate_from_beginning_and_insert(wallet)

  defp calculate_amounts(wallet, %{"computed_balance" => computed_balance, "tokens" => tokens}) do
    tokens_id = Enum.map(tokens, fn token -> token.id end)

    wallet.address
    |> Entry.calculate_all_balances(%{
      since: computed_balance.computed_at,
      token_id: tokens_id
    })
    |> add_amounts(computed_balance.amounts)
  end

  defp calculate_amounts(wallet, %{"computed_balance" => computed_balance}) do
    wallet.address
    |> Entry.calculate_all_balances(%{
      since: computed_balance.computed_at
    })
    |> add_amounts(computed_balance.amounts)
  end

  defp add_amounts(amounts_1, amounts_2) do
    (Map.keys(amounts_1) ++ Map.keys(amounts_2))
    |> Enum.into(
      %{},
      fn token_id ->
        {token_id, (amounts_1[token_id] || 0) + (amounts_2[token_id] || 0)}
      end
    )
  end

  #
  # Private functions for calculating and storing the cached balances.
  #

  defp calculate_with_strategy("since_last_cached", wallet) do
    case CachedBalance.get(wallet.address) do
      nil ->
        calculate_from_beginning_and_insert(wallet)

      computed_balance ->
        :local_ledger
        |> Application.get_env(:balance_caching_reset_frequency)
        |> calculate_with_reset_frequency(wallet, computed_balance)
    end
  end

  defp calculate_with_strategy("since_beginning", wallet) do
    calculate_from_beginning_and_insert(wallet)
  end

  defp calculate_with_strategy(_, wallet) do
    calculate_with_strategy("since_beginning", wallet)
  end

  defp calculate_with_reset_frequency(frequency, wallet, %{cached_count: cached_count})
       when is_number(frequency) and frequency > 0 and cached_count >= frequency - 1 do
    calculate_from_beginning_and_insert(wallet)
  end

  defp calculate_with_reset_frequency(_, wallet, computed_balance) do
    calculate_from_cached_and_insert(wallet, computed_balance)
  end

  defp calculate_from_beginning_and_insert(wallet) do
    computed_at = NaiveDateTime.utc_now()

    wallet.address
    |> Entry.calculate_all_balances(%{upto: computed_at})
    |> insert(wallet, computed_at, 1)
  end

  defp calculate_from_beginning_and_insert(wallet, tokens) do
    computed_at = NaiveDateTime.utc_now()
    token_ids = Enum.map(tokens, fn token -> token.id end)

    wallet.address
    |> Entry.calculate_all_balances(%{upto: computed_at, token_id: token_ids})
    |> insert(wallet, computed_at, 1)
  end

  defp calculate_from_cached_and_insert(wallet, computed_balance) do
    computed_at = NaiveDateTime.utc_now()

    wallet.address
    |> Entry.calculate_all_balances(%{
      since: computed_balance.computed_at,
      upto: computed_at
    })
    |> add_amounts(computed_balance.amounts)
    |> insert(wallet, computed_at, computed_balance.cached_count + 1)
  end

  defp insert(amounts, wallet, computed_at, cached_count) do
    _ =
      if Enum.any?(amounts, fn {_token, amount} -> amount > 0 end) do
        {:ok, _} =
          CachedBalance.insert(%{
            amounts: amounts,
            wallet_address: wallet.address,
            cached_count: cached_count,
            computed_at: computed_at
          })
      end

    amounts
  end
end
