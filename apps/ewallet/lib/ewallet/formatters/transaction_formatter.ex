defmodule EWallet.TransactionFormatter do
  @moduledoc """
  Converts an eWallet's transaction into a LocalLedger's transaction and entries.
  """
  alias EWalletDB.{Account, Transaction}
  alias EWalletDB.Helpers.Preloader
  alias LocalLedgerDB.Entry

  @doc """
  Formats a transaction the way LocalLedger expects it.
  """
  @spec format(%Transaction{}) :: map()
  def format(transaction) do
    %{
      "idempotency_token" => transaction.idempotency_token,
      "metadata" => transaction.metadata,
      "entries" => entries(transaction)
    }
  end

  # Entries for a same-token transfer
  defp entries(%{from_token: %{uuid: from}, to_token: %{uuid: to}} = txn) when from == to do
    [
      entry(:debit, txn.from_wallet, txn.from_amount, txn.from_token),
      entry(:credit, txn.to_wallet, txn.to_amount, txn.to_token)
    ]
  end

  # Entries for a cross-token transfer/exchange
  defp entries(%{from_token: %{uuid: from}, to_token: %{uuid: to}} = txn) when from != to do
    exchange_wallet =
      txn
      |> Preloader.preload(:exchange_account)
      |> Map.get(:exchange_account)
      |> Account.get_primary_wallet()

    [
      entry(:debit, txn.from_wallet, txn.from_amount, txn.from_token),
      entry(:credit, exchange_wallet, txn.from_amount, txn.from_token),
      entry(:debit, exchange_wallet, txn.to_amount, txn.to_token),
      entry(:credit, txn.to_wallet, txn.to_amount, txn.to_token)
    ]
  end

  # A generic entry builder
  defp entry(:debit, wallet, amount, token) do
    entry(Entry.debit_type(), wallet, amount, token)
  end

  defp entry(:credit, wallet, amount, token) do
    entry(Entry.credit_type(), wallet, amount, token)
  end

  defp entry(type, wallet, amount, token) do
    %{
      "type" => type,
      "address" => wallet.address,
      "amount" => amount,
      "token" => %{
        "id" => token.id,
        "metadata" => token.metadata
      },
      "metadata" => wallet.metadata
    }
  end
end
