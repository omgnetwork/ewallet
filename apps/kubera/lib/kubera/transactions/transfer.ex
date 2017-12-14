defmodule Kubera.Transactions.Transfer do
  @moduledoc """
  Handles the logic for a transfer of value between two addresses.
  """
  alias KuberaMQ.Serializers.Transaction
  alias KuberaMQ.Entry
  alias KuberaDB.Transfer

  @doc """
  Gets or inserts a transfer using the given idempotency token and other given attributes.

  ## Examples

    res = Transactions.Transfer.get_or_insert(%{
      idempotency_token: "84bafebf-9776-4cb0-a7f7-8b1e5c7ec830",
      from: "c4f829d0-fe85-4b4c-a326-0c46f26b47c5",
      to: "f084d20b-6aa7-4231-803f-a0d8d938f939",
      minted_token_id: "f7ef021b-95bf-45c8-990f-743ca99d742a",
      amount: 10,
      metadata: %{},
      payload: %{}
    })

    case res do
      {:ok, transfer} ->
        # Everything went well, do something.
      {:error, changeset} ->
        # Something went wrong with the Transfer insert.
    end

  """
  def get_or_insert(%{
    idempotency_token: _,
    from: _,
    to: _,
    minted_token_id: _,
    amount: _,
    metadata: _,
    payload: _
  } = attrs) do
    attrs
    |> Map.put(:type, Transfer.internal)
    |> Transfer.get_or_insert()
  end

  @doc """
  Process a transfer and sends the transaction to the ledger(s).

  ## Examples

    res = Transactions.Transfer.process(transfer)

    case res do
      {:ok, ledger_response} ->
        # Everything went well, do something.
      {:error, code, description} ->
        # Something went wrong with the transfer processing.
    end

  """
  def process(transfer) do
    transfer
    |> Transaction.serialize()
    |> Entry.insert(transfer.idempotency_token)
    |> update_transfer(transfer)
  end

  @doc """
  Process a genesis transfer and sends the transaction to the ledger(s).

  ## Examples

    res = Transactions.Transfer.genesis(transfer)

    case res do
      {:ok, ledger_response} ->
        # Everything went well, do something.
      {:error, code, description} ->
        # Something went wrong with the transfer processing.
    end

  """
  def genesis(transfer) do
    transfer
    |> Transaction.serialize()
    |> Entry.genesis(transfer.idempotency_token)
    |> update_transfer(transfer)
  end

  defp update_transfer({:ok, ledger_response}, transfer) do
    transfer = Transfer.confirm(transfer, ledger_response)
    {:ok, transfer}
  end
  defp update_transfer({:error, code, description}, transfer) do
    Transfer.fail(transfer, %{
      code: code,
      description: description
    })

    {:error, code, description}
  end
end
