defmodule LocalLedger.CachedBalance do
  @moduledoc """
  This module is an interface to the abstract balances stored in DB. It is responsible for caching
  wallets and serves as an interface to retrieve the current balances (which will either be
  loaded from a cached balance or computed - or both).
  """
  alias LocalLedgerDB.{Wallet, CachedBalance, Transaction}

  @doc """
  Cache all the wallets balances using a batch stream mechanism for retrieval (1000 at a time). This
  is meant to be used in some kind of schedulers, but can also be ran manually.
  """
  @spec cache_all() :: :ok
  def cache_all do
    Wallet.stream_all(fn wallet ->
      {:ok, calculate_with_strategy(wallet)}
    end)
  end

  @doc """
  Get all the balances for the given wallet.
  """
  @spec all(Wallet.t()) :: {:ok, Map.t()}
  def all(wallet) do
    {:ok, get_amounts(wallet)}
  end

  @doc """
  Get the balance for the specified token (token_id) and
  the given wallet.
  """
  @spec get(Wallet.t(), String.t()) :: {:ok, Map.t()}
  def get(wallet, token_id) do
    amounts = get_amounts(wallet)
    {:ok, %{token_id => amounts[token_id] || 0}}
  end

  defp get_amounts(wallet) do
    wallet.address
    |> CachedBalance.get()
    |> calculate_amounts(wallet)
  end

  defp calculate_amounts(nil, wallet), do: calculate_from_beginning_and_insert(wallet)

  defp calculate_amounts(computed_balance, wallet) do
    wallet.address
    |> Transaction.calculate_all_balances(%{
      since: computed_balance.computed_at
    })
    |> add_amounts(computed_balance.amounts)
  end

  defp add_amounts(amounts_1, amounts_2) do
    (Map.keys(amounts_1) ++ Map.keys(amounts_2))
    |> Enum.map(fn token_id ->
      {token_id, (amounts_1[token_id] || 0) + (amounts_2[token_id] || 0)}
    end)
    |> Enum.into(%{})
  end

  defp calculate_with_strategy(wallet) do
    :local_ledger
    |> Application.get_env(:balance_caching_strategy)
    |> calculate_with_strategy(wallet)
  end

  defp calculate_with_strategy("since_last_cached", wallet) do
    case CachedBalance.get(wallet.address) do
      nil -> calculate_from_beginning_and_insert(wallet)
      computed_balance -> calculate_from_cached_and_insert(wallet, computed_balance)
    end
  end

  defp calculate_with_strategy("since_beginning", wallet) do
    calculate_from_beginning_and_insert(wallet)
  end

  defp calculate_with_strategy(_, wallet) do
    calculate_with_strategy("since_beginning", wallet)
  end

  defp calculate_from_beginning_and_insert(wallet) do
    computed_at = NaiveDateTime.utc_now()

    wallet.address
    |> Transaction.calculate_all_balances(%{upto: computed_at})
    |> insert(wallet, computed_at)
  end

  defp calculate_from_cached_and_insert(wallet, computed_balance) do
    computed_at = NaiveDateTime.utc_now()

    wallet.address
    |> Transaction.calculate_all_balances(%{
      since: computed_balance.computed_at,
      upto: computed_at
    })
    |> add_amounts(computed_balance.amounts)
    |> insert(wallet, computed_at)
  end

  defp insert(amounts, wallet, computed_at) do
    _ =
      if Enum.any?(amounts, fn {_token, amount} -> amount > 0 end) do
        {:ok, _} =
          CachedBalance.insert(%{
            amounts: amounts,
            wallet_address: wallet.address,
            computed_at: computed_at
          })
      end

    amounts
  end
end
