defmodule LocalLedger.Balance do
  @moduledoc """
  This module is an interface to the LocalLedgerDB schema (Balance and Transaction)
  and contains the logic needed to lock a list of addresses.
  """
  alias LocalLedger.CachedBalance
  alias LocalLedgerDB.{Repo, Balance}

  @doc """
  Calculate and returns the current balances for each minted token associated
  with the given address.
  """
  def all(address) do
    case Balance.get(address) do
      nil -> {:ok, %{}}
      balance -> CachedBalance.all(balance)
    end
  end

  @doc """
  Calculate and returns the current balance for the specified minted token
  associated with the given address.
  """
  def get(friendly_id, address) do
    case Balance.get(address) do
      nil -> {:ok, %{}}
      balance -> CachedBalance.get(balance, friendly_id)
    end
  end

  @doc """
  Run the given function in a safe environment by locking all the matching
  balances.
  """
  def lock(addresses, fun) do
    Repo.transaction fn ->
      Balance.lock(addresses)
      res = fun.()
      Balance.touch(addresses)
      res
    end
  end
end
