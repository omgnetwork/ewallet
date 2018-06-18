defmodule LocalLedger.Wallet do
  @moduledoc """
  This module is an interface to the LocalLedgerDB schema (Balance, CachedBalance
  and Entry) and contains the logic needed to lock a list of addresses.
  """
  alias LocalLedger.CachedBalance
  alias LocalLedgerDB.{Repo, Wallet}

  @doc """
  Calculate and returns the current wallets for each token associated
  with the given address.
  """
  def all_balances(address) do
    case Wallet.get(address) do
      nil -> {:ok, %{}}
      balance -> CachedBalance.all(balance)
    end
  end

  @doc """
  Calculate and returns the current balance for the specified token
  associated with the given address.
  """
  def get_balance(token_id, address) do
    case Wallet.get(address) do
      nil -> {:ok, %{}}
      balance -> CachedBalance.get(balance, token_id)
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
