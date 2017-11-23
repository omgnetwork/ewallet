defmodule Kubera.Transaction do
  @moduledoc """
  Handles the logic for a transfer of value between two addresses.
  """
  alias KuberaMQ.Serializers.Transaction
  alias KuberaMQ.Entry
  alias Kubera.Transactions.{RecordFetcher, BalanceLoader, Formatter}
  alias KuberaDB.Transfer

  def credit_type, do: "credit"
  def debit_type, do: "debit"

  def process(%{
    "provider_user_id" => provider_user_id,
    "token_id" => token_friendly_id,
    "amount" => _,
    "metadata" => _,
    "idempotency_token" => _,
    "type" => _
  } = attrs) do
    res = fetch_user_and_minted_token(provider_user_id, token_friendly_id)

    case res do
      {:ok, user, minted_token} ->
        attrs
        |> get_or_insert_transfer()
        |> process_with_transfer(user, minted_token, attrs)
      {:error, code} ->
        {:error, code}
    end
  end

  defp get_or_insert_transfer(%{
    "idempotency_token" => idempotency_token,
    "metadata" => metadata
  } = attrs) do
    Transfer.get_or_insert(%{
      idempotency_token: idempotency_token,
      type: Transfer.internal,
      payload: attrs,
      metadata: metadata
    })
  end

  defp process_with_transfer(%Transfer{status: "pending"} = transfer, user, minted_token, %{
      "type" => type,
      "amount" => amount,
      "metadata" => metadata
  }) do
    user
    |> load_balances(minted_token, type)
    |> format(amount, metadata)
    |> insert(transfer.idempotency_token)
    |> update_transfer(transfer)
    |> return(user, minted_token)
  end
  defp process_with_transfer(%Transfer{status: "confirmed"} = transfer, user, minted_token, _) do
    return({:ok, transfer.ledger_response}, user, minted_token)
  end
  defp process_with_transfer(%Transfer{status: "failed"} = transfer, user, minted_token, _) do
    resp = transfer.ledger_response
    return({:error, resp["code"], resp["description"]}, user, minted_token)
  end

  defp fetch_user_and_minted_token(provider_user_id, token_friendly_id) do
    RecordFetcher.fetch_user_and_minted_token(provider_user_id, token_friendly_id)
  end

  defp load_balances(user, minted_token, type) do
    BalanceLoader.load(user, minted_token, type)
  end

  defp format({minted_token, from, to}, amount, metadata) do
    Formatter.format(from, to, minted_token, amount, metadata)
  end

  defp insert(attrs, idempotency_token) do
    attrs |> Transaction.serialize() |> Entry.insert(idempotency_token)
  end

  defp update_transfer({:ok, ledger_response}, transfer) do
    Transfer.confirm(transfer, ledger_response)
    {:ok, ledger_response}
  end
  defp update_transfer({:error, code, description}, transfer) do
    Transfer.fail(transfer, %{
      code: code,
      description: description
    })

    {:error, code, description}
  end

  defp return({:ok, _ledger_response}, user, minted_token), do: {:ok, user, minted_token}
  defp return({:error, code, description}, _user, _minted_token), do: {:error, code, description}
end
