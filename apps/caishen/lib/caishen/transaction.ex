defmodule Caishen.Transaction do
  @moduledoc """
  This module is responsible for preparing and formatting the transactions
  before they are passed to an entry to be inserted in the database.
  """
  alias CaishenDB.{Balance, MintedToken, Transaction}

  @doc """
  Get or insert the given minted token and all the given addresses before
  building a map representation usable by the CaishenDB schemas.
  """
  def build_all({debits, credits}, minted_token) do
    {:ok, minted_token} = MintedToken.get_or_insert(minted_token)
    sending = format(minted_token, debits, Transaction.debit_type)
    receiving = format(minted_token, credits, Transaction.credit_type)

    sending ++ receiving
  end

  @doc """
  Extract the list of DEBIT addresses.
  """
  def get_addresses(transactions) do
    transactions
    |> Enum.filter(fn transaction ->
      transaction[:type] == Transaction.debit_type
    end)
    |> Enum.map(fn transaction -> transaction[:balance_address] end)
  end

  # Build a list of balance maps with the required details for DB insert.
  defp format(minted_token, balances, type) do
    Enum.map balances, fn attrs ->
      {:ok, balance} = Balance.get_or_insert(attrs)

      %{
        type: type,
        amount: attrs["amount"],
        minted_token_friendly_id: minted_token.friendly_id,
        balance_address: balance.address,
      }
    end
  end

  @doc """
  Match when genesis is set to true and does... nothing.
  """
  def check_balance(_, %{genesis: true}) do
    :ok
  end

  @doc """
  Match when genesis is false and run the balance check.
  """
  def check_balance(transactions, %{genesis: _}) do
    check_balance(transactions)
  end

  @doc """
  Check the current balance amount for each DEBIT transaction.
  """
  def check_balance(transactions) do
    Enum.each transactions, fn transaction ->
      if transaction[:type] == Transaction.debit_type do
        Transaction.check_balance(%{
          amount: transaction[:amount],
          friendly_id: transaction[:minted_token_friendly_id],
          address: transaction[:balance_address]
        })
      end
    end
  end
end
