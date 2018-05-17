defmodule LocalLedger.CachedBalance do
  @moduledoc """
  This module is an interface to the LocalLedgerDB Balance schema. It is responsible for caching
  balances and serves as an interface to retrieve the current balances (which will either be
  loaded from a cached balance or computed - or both).
  """
  alias LocalLedgerDB.{Balance, CachedBalance, Transaction}

  @doc """
  Cache all the balances using a batch stream mechanism for retrieval (1000 at a time). This
  is meant to be used in some kind of schedulers, but can also be ran manually.
  """
  @spec cache_all() :: {}
  def cache_all do
    Balance.stream_all(fn balance ->
      {:ok, calculate_with_strategy(balance)}
    end)
  end

  @doc """
  Get all the balance amounts for the given balance.
  """
  @spec all(Balance.t()) :: {:ok, Map.t()}
  def all(balance) do
    {:ok, get_amounts(balance)}
  end

  @doc """
  Get the balance amount for the specified minted token (token_id) and
  the given balance.
  """
  @spec get(Balance.t(), String.t()) :: {:ok, Map.t()}
  def get(balance, token_id) do
    amounts = get_amounts(balance)
    {:ok, %{token_id => amounts[token_id] || 0}}
  end

  defp get_amounts(balance) do
    balance.address
    |> CachedBalance.get()
    |> calculate_amounts(balance)
  end

  defp calculate_amounts(nil, balance), do: calculate_from_beginning_and_insert(balance)

  defp calculate_amounts(cached_balance, balance) do
    balance.address
    |> Transaction.calculate_all_balances(%{
      since: cached_balance.computed_at
    })
    |> add_amounts(cached_balance.amounts)
  end

  defp add_amounts(amounts_1, amounts_2) do
    (Map.keys(amounts_1) ++ Map.keys(amounts_2))
    |> Enum.map(fn token_id ->
      {token_id, (amounts_1[token_id] || 0) + (amounts_2[token_id] || 0)}
    end)
    |> Enum.into(%{})
  end

  defp calculate_with_strategy(balance) do
    :local_ledger
    |> Application.get_env(:balance_caching_strategy)
    |> calculate_with_strategy(balance)
  end

  defp calculate_with_strategy("since_last_cached", balance) do
    case CachedBalance.get(balance.address) do
      nil -> calculate_from_beginning_and_insert(balance)
      cached_balance -> calculate_from_cached_and_insert(balance, cached_balance)
    end
  end

  defp calculate_with_strategy("since_beginning", balance) do
    calculate_from_beginning_and_insert(balance)
  end

  defp calculate_with_strategy(_, balance) do
    calculate_with_strategy("since_beginning", balance)
  end

  defp calculate_from_beginning_and_insert(balance) do
    computed_at = NaiveDateTime.utc_now()

    balance.address
    |> Transaction.calculate_all_balances(%{upto: computed_at})
    |> insert(balance, computed_at)
  end

  defp calculate_from_cached_and_insert(balance, cached_balance) do
    computed_at = NaiveDateTime.utc_now()

    balance.address
    |> Transaction.calculate_all_balances(%{
      since: cached_balance.computed_at,
      upto: computed_at
    })
    |> add_amounts(cached_balance.amounts)
    |> insert(balance, computed_at)
  end

  defp insert(amounts, balance, computed_at) do
    if Enum.any?(amounts, fn {_token, amount} -> amount > 0 end) do
      {:ok, _} =
        CachedBalance.insert(%{
          amounts: amounts,
          wallet_address: balance.address,
          computed_at: computed_at
        })
    end

    amounts
  end
end
