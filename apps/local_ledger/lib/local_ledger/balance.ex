defmodule LocalLedger.Balance do
  @moduledoc """
  This module is an interface to the LocalLedgerDB schema (Balance and Transaction)
  and contains the logic needed to lock a list of addresses.
  """
  alias LocalLedgerDB.{Repo, Balance, Transaction}

  @doc """
  Calculate and returns the current balances for each minted token associated
  with the given address.
  """
  def all(address) do
    {:ok, Transaction.calculate_all_balances(address)}
  end

  @doc """
  Calculate and returns the current balance for the specified minted token
  associated with the given address.
  """
  def get(friendly_id, address) do
    {:ok, Transaction.calculate_all_balances(address, friendly_id)}
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
