defmodule LocalLedger.Entry do
  @moduledoc """
  This module is responsible for preparing and formatting the entries
  before they are passed to a transaction to be inserted in the database.
  """
  alias LocalLedgerDB.{Wallet, Token, Entry}

  @doc """
  Get or insert the given token and all the given addresses before
  building a map representation usable by the LocalLedgerDB schemas.
  """
  def build_all({debits, credits}) do
    debits = format(debits, Entry.debit_type())
    credits = format(credits, Entry.credit_type())

    debits ++ credits
  end

  # Build a list of wallet maps with the required details for DB insert.
  defp format(entries, type) do
    Enum.map(entries, fn attrs ->
      {:ok, token} = Token.get_or_insert(attrs["token"])
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
  Extract the list of DEBIT addresses.
  """
  def get_addresses(entries) do
    entries
    |> Enum.filter(fn entry ->
      entry[:type] == Entry.debit_type()
    end)
    |> Enum.map(fn entry -> entry[:wallet_address] end)
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
  def check_balance(entries, %{genesis: _}) do
    check_balance(entries)
  end

  @doc """
  Check the current wallet amount for each DEBIT entry.
  """
  def check_balance(entries) do
    Enum.each(entries, fn entry ->
      if entry[:type] == Entry.debit_type() do
        Entry.check_balance(%{
          amount: entry[:amount],
          token_id: entry[:token_id],
          address: entry[:wallet_address]
        })
      end
    end)
  end
end
