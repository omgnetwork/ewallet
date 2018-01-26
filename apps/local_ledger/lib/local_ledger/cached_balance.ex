defmodule LocalLedger.CachedBalance do
  @moduledoc """

  """
  alias LocalLedgerDB.{CachedBalance, Transaction}

  def cache_all() do
    LocalLedgerDB.Balance.stream_all(fn balance ->
      case CachedBalance.get(balance.address) do
        nil            -> {:ok, calculate_and_insert(balance)}
        cached_balance -> {:ok, calculate_and_insert(balance, cached_balance)}
      end
    end)
  end

  def all(balance) do
    {:ok, get_amounts(balance)}
  end

  def get(balance, friendly_id) do
    amounts = get_amounts(balance)
    {:ok, %{friendly_id => amounts[friendly_id] || 0}}
  end

  defp get_amounts(balance) do
    balance.address
    |> CachedBalance.get()
    |> calculate_amounts(balance)
  end

  defp calculate_amounts(nil, balance), do: calculate_and_insert(balance)
  defp calculate_amounts(cached_balance, balance) do
    balance
    |> calculate_since(cached_balance.computed_at)
    |> add_amounts(cached_balance.amounts)
  end

  defp add_amounts(amounts_1, amounts_2) do
    Map.keys(amounts_1) ++ Map.keys(amounts_2)
    |> Enum.map(fn friendly_id ->
      {friendly_id, (amounts_1[friendly_id] || 0) + (amounts_2[friendly_id] || 0)}
    end)
    |> Enum.into(%{})
  end

  defp calculate_since(balance, datetime) do
    Transaction.calculate_all_balances(balance.address, %{since: datetime})
  end

  defp calculate_and_insert(balance, cached_balance) do
    computed_at = NaiveDateTime.utc_now()

    amounts = cached_balance.amounts

    {:ok, _} = CachedBalance.insert(%{
      amounts:         amounts,
      balance_address: balance.address,
      computed_at:     computed_at
    })

    amounts
  end

  defp calculate_and_insert(balance) do
    computed_at = NaiveDateTime.utc_now()

    amounts = Transaction.calculate_all_balances(balance.address, %{
      upto: computed_at
    })

    {:ok, _} = CachedBalance.insert(%{
      amounts:         amounts,
      balance_address: balance.address,
      computed_at:     computed_at
    })

    amounts
  end
end
