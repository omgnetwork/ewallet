defmodule EWallet.TransferGate do
  @moduledoc """
  Handles the logic for a transfer of value between two addresses.
  """
  alias EWallet.TransactionFormatter
  alias EWalletDB.{Account, Token, Transaction}
  alias LocalLedger.Transaction, as: LedgerTransaction

  @doc """
  Gets or inserts a transaction using the given idempotency token and other given attributes.

  ## Examples

    res = TransferGate.get_or_insert(%{
      idempotency_token: "84bafebf-9776-4cb0-a7f7-8b1e5c7ec830",
      from: "c4f829d0-fe85-4b4c-a326-0c46f26b47c5",
      to: "f084d20b-6aa7-4231-803f-a0d8d938f939",
      from_amount: 10,
      from_token_id: "tok_OMG_1234567890990f743ca99d742a",
      to_amount: 10,
      to_token_id: "tok_OMG_1234567890990f743ca99d742a",
      exchange_account_id: nil,
      metadata: %{},
      encrypted_metadata: %{},
      payload: %{}
    })

    case res do
      {:ok, transaction} ->
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
          from_amount: _,
          from_token_id: _,
          to_amount: _,
          from_token_id: _,
          exchange_account_id: _,
          payload: _
        } = attrs
      ) do
    attrs
    |> Map.put(:type, Transaction.internal())
    |> Map.put(:from_token_uuid, Token.get_by(id: attrs.from_token_id).uuid)
    |> Map.put(:to_token_uuid, Token.get_by(id: attrs.to_token_id).uuid)
    |> Map.put(
      :exchange_account_uuid,
      case attrs.exchange_account_id do
        nil ->
          nil

        id ->
          case Account.get(id) do
            %Account{uuid: uuid} -> uuid
            _ -> nil
          end
      end
    )
    |> Transaction.get_or_insert()
  end

  @doc """
  Process a transaction and sends the transaction to the ledger(s).

  ## Examples

    res = TransferGate.process(transaction)

    case res do
      {:ok, transaction} ->
        # Everything went well, do something.
      {:error, code, description} ->
        # Something went wrong with the transaction processing.
    end

  """
  def process(transaction) do
    transaction
    |> TransactionFormatter.format()
    |> LedgerTransaction.insert(%{genesis: false})
    |> update_transaction(transaction)
  end

  @doc """
  Process a genesis transaction and sends the transaction to the ledger(s).

  ## Examples

    res = TransferGate.genesis(transaction)

    case res do
      {:ok, transaction} ->
        # Everything went well, do something.
      {:error, code, description} ->
        # Something went wrong with the transaction processing.
    end

  """
  def genesis(transaction) do
    transaction
    |> TransactionFormatter.format()
    |> LedgerTransaction.insert(%{genesis: true})
    |> update_transaction(transaction)
  end

  defp update_transaction(
         _,
         %Transaction{local_ledger_uuid: local_ledger_uuid, error_code: error_code} = transaction
       )
       when local_ledger_uuid != nil
       when error_code != nil do
    transaction
  end

  defp update_transaction({:ok, tranasction}, transaction) do
    Transaction.confirm(transaction, tranasction.uuid)
  end

  defp update_transaction({:error, code, description}, transaction) do
    Transaction.fail(transaction, code, description)
  end
end
