defmodule EWallet.TransferGate do
  @moduledoc """
  Handles the logic for a transfer of value between two addresses.
  """
  alias EWallet.TransactionFormatter
  alias EWalletDB.{Token, Transaction}
  alias LocalLedger.Transaction, as: LedgerTransaction

  @doc """
  Gets or inserts a transfer using the given idempotency token and other given attributes.

  ## Examples

    res = TransferGate.get_or_insert(%{
      idempotency_token: "84bafebf-9776-4cb0-a7f7-8b1e5c7ec830",
      from: "c4f829d0-fe85-4b4c-a326-0c46f26b47c5",
      to: "f084d20b-6aa7-4231-803f-a0d8d938f939",
      token_id: "f7ef021b-95bf-45c8-990f-743ca99d742a",
      amount: 10,
      metadata: %{},
      encrypted_metadata: %{},
      payload: %{}
    })

    case res do
      {:ok, transfer} ->
        # Everything went well, do something.
      {:error, changeset} ->
        # Something went wrong with the Transfer insert.
    end

  """
  def get_or_insert(
        %{
          idempotency_token: _,
          from: _,
          to: _,
          token_id: _,
          amount: _,
          payload: _
        } = attrs
      ) do
    attrs
    |> Map.put(:type, Transaction.internal())
    |> Map.put(:from_amount, attrs.amount)
    |> Map.put(:from_token_uuid, Token.get_by(id: attrs.token_id).uuid)
    |> Map.put(:to_amount, attrs.amount)
    |> Map.put(:to_token_uuid, Token.get_by(id: attrs.token_id).uuid)
    |> Transaction.get_or_insert()
  end

  @doc """
  Process a transfer and sends the transaction to the ledger(s).

  ## Examples

    res = TransferGate.process(transfer)

    case res do
      {:ok, transfer} ->
        # Everything went well, do something.
      {:error, code, description} ->
        # Something went wrong with the transfer processing.
    end

  """
  def process(transfer) do
    transfer
    |> TransactionFormatter.format()
    |> LedgerTransaction.insert(%{genesis: false})
    |> update_transfer(transfer)
  end

  @doc """
  Process a genesis transfer and sends the transaction to the ledger(s).

  ## Examples

    res = TransferGate.genesis(transfer)

    case res do
      {:ok, transfer} ->
        # Everything went well, do something.
      {:error, code, description} ->
        # Something went wrong with the transfer processing.
    end

  """
  def genesis(transfer) do
    transfer
    |> TransactionFormatter.format()
    |> LedgerTransaction.insert(%{genesis: true})
    |> update_transfer(transfer)
  end

  defp update_transfer(_, %Transaction{local_ledger_transaction_uuid: local_ledger_uuid,
                                       error_code: error_code} = transfer)
       when local_ledger_uuid != nil
       when error_code != nil do
    transfer
  end

  defp update_transfer({:ok, tranasction}, transfer) do
    Transaction.confirm(transfer, tranasction.uuid)
  end

  defp update_transfer({:error, code, description}, transfer) do
    Transaction.fail(transfer, code, description)
  end
end
