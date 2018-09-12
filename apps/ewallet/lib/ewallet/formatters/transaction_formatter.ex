defmodule EWallet.TransactionFormatter do
  @moduledoc """
  Converts an eWallet's transaction into a LocalLedger's transaction and entries.
  """
  alias EWalletDB.Helpers.Preloader
  alias EWalletDB.Transaction
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

  # Prepare entries for a same-token transfer
  defp entries(%{from_token: %{uuid: same_uuid}, to_token: %{uuid: same_uuid}} = txn) do
    [
      entry(:debit, txn.from_wallet, txn.from_amount, txn.from_token),
      entry(:credit, txn.to_wallet, txn.to_amount, txn.to_token)
    ]
  end

  # Prepare entries for a cross-token transfer from the exchange wallet
  defp entries(%{from: same_address, exchange_wallet_address: same_address} = txn) do
    [
      # This transfer has only 2 entries because the to-be-exchanged amount
      # comes from the exchange wallet itself. It only needs to debit the to_token amount
      # from the exchange wallet and credit it to the `to` wallet.
      entry(:debit, txn.from_wallet, txn.to_amount, txn.to_token),
      entry(:credit, txn.to_wallet, txn.to_amount, txn.to_token)
    ]
  end

  # Prepare entries for a cross-token transfer to the exchange wallet
  defp entries(%{to: same_address, exchange_wallet_address: same_address} = txn) do
    [
      # This transfer has only 2 entries because the exchanged amount stays in
      # the exchange wallet itself. It only needs to debit the from_token amount
      # from the `from` wallet and credit it to the exchange wallet.
      entry(:debit, txn.from_wallet, txn.from_amount, txn.from_token),
      entry(:credit, txn.to_wallet, txn.from_amount, txn.from_token)
    ]
  end

  # Prepare entries for a cross-token transfer/exchange
  defp entries(txn) do
    exchange_wallet =
      txn
      |> Preloader.preload(:exchange_wallet)
      |> Map.get(:exchange_wallet)

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
