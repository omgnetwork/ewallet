defmodule LocalLedger.Transaction do
  @moduledoc """
  This module is responsible for preparing and formatting the transactions
  before they are passed to an entry to be inserted in the database.
  """
  alias LocalLedgerDB.{Wallet, Token, Transaction}

  @doc """
  Get or insert the given token and all the given addresses before
  building a map representation usable by the LocalLedgerDB schemas.
  """
  def build_all({debits, credits}, token) do
    {:ok, token} = Token.get_or_insert(token)
    sending = format(token, debits, Transaction.debit_type())
    receiving = format(token, credits, Transaction.credit_type())

    sending ++ receiving
  end

  @doc """
  Extract the list of DEBIT addresses.
  """
  def get_addresses(transactions) do
    transactions
    |> Enum.filter(fn transaction ->
      transaction[:type] == Transaction.debit_type()
    end)
    |> Enum.map(fn transaction -> transaction[:wallet_address] end)
  end

  # Build a list of wallet maps with the required details for DB insert.
  defp format(token, wallets, type) do
    Enum.map(wallets, fn attrs ->
      {:ok, wallet} = Wallet.get_or_insert(attrs)

      %{
        type: type,
        amount: attrs["amount"],
        token_id: token.id,
        wallet_address: wallet.address
      }
    end)
  end

  @doc """
  Match when genesis is set to true and does... nothing.
  """
  def check_balance(_, %{genesis: true}) do
    :ok
  end

  @doc """
  Match when genesis is false and run the wallet check.
  """
  def check_balance(transactions, %{genesis: _}) do
    check_balance(transactions)
  end

  @doc """
  Check the current wallet amount for each DEBIT transaction.
  """
  def check_balance(transactions) do
    Enum.each(transactions, fn transaction ->
      if transaction[:type] == Transaction.debit_type() do
        Transaction.check_balance(%{
          amount: transaction[:amount],
          token_id: transaction[:token_id],
          address: transaction[:wallet_address]
        })
      end
    end)
  end
end
