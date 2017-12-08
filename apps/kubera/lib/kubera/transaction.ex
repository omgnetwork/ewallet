defmodule Kubera.Transaction do
  @moduledoc """
  Handles the logic for a transfer of value from an account to a user. Delegates the
  actual transfer to Kubera.Transactions.Transfer once the balances have been loaded.
  """
  alias Kubera.Transactions.{RecordFetcher, BalanceLoader}
  alias KuberaDB.Transfer

  def credit_type, do: "credit"
  def debit_type, do: "debit"

  @doc """
  Process a transaction, starting with the creation or retrieval of a transfer record (using
  the given idempotency token), then calling the Transfer.process function to add the transaction
  to the ledger(s).

  ## Examples

    res = Transaction.process(%{
      "account_id" => "510f32b5-17f4-4c5c-86f2-aad1396330f9", # Optional
      "burn_balance_identifier" => "burn", # Optional
      "provider_user_id" => "sample_provider_user_id",
      "token_id" => "OMG:"a5f64c8c-9f3b-4247-b01c-098a7e204142"",
      "amount" => 100_000,
      "type" => Transaction.debit_type,
      "metadata" => %{some: "data"},
      "idempotency_token" => idempotency_token
    })

    case res do
      {:ok, user, minted_token} ->
        # Everything went well, do something.
      {:error, code, description} ->
        # Something went wrong with the transfer processing.
    end

  """
  def process(%{
    "provider_user_id" => _,
    "token_id" => _,
    "amount" => amount,
    "metadata" => metadata,
    "idempotency_token" => idempotency_token,
    "type" => type
  } = attrs) do
    burn_balance_identifier = attrs["burn_balance_identifier"]

    with {:ok, account, user, minted_token} <- RecordFetcher.fetch(attrs),
         {:ok, from, to} <- BalanceLoader.load(account, user, type, burn_balance_identifier),
         {:ok, transfer} <- Kubera.Transactions.Transfer.get_or_insert(%{
           idempotency_token: idempotency_token,
           from: from.address,
           to: to.address,
           minted_token_id: minted_token.id,
           amount: amount,
           metadata: metadata,
           payload: attrs
         })
    do
      process_with_transfer(transfer, user, minted_token)
    else
      error -> error
    end
  end

  defp process_with_transfer(%Transfer{status: "pending"} = transfer, user, minted_token) do
    transfer
    |> Kubera.Transactions.Transfer.process()
    |> return(user, minted_token)
  end
  defp process_with_transfer(%Transfer{status: "confirmed"} = transfer, user, minted_token) do
    return({:ok, transfer.ledger_response}, user, minted_token)
  end
  defp process_with_transfer(%Transfer{status: "failed"} = transfer, user, minted_token) do
    resp = transfer.ledger_response
    return({:error, resp["code"], resp["description"]}, user, minted_token)
  end

  defp return({:ok, _ledger_response}, user, minted_token), do: {:ok, user, minted_token}
  defp return({:error, code, description}, _user, _minted_token), do: {:error, code, description}
end
