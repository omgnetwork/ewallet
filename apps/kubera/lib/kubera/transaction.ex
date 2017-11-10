defmodule Kubera.Transaction do
  @moduledoc """
  Handles the logic for a transfer of value between two addresses.
  """
  alias KuberaMQ.Serializers.Transaction
  alias KuberaMQ.Entry
  alias Kubera.Transactions.{RecordFetcher, BalanceLoader, Formatter}

  def credit_type, do: "credit"
  def debit_type, do: "debit"

  def process(%{
    "provider_user_id" => provider_user_id,
    "symbol" => symbol,
    "amount" => amount,
    "metadata" => metadata
  }, type) do
    res = fetch_user_and_minted_token(provider_user_id, symbol)

    case res do
      {:ok, user, minted_token} = res ->
        res
        |> load_balances(type)
        |> format(amount, metadata)
        |> insert()
        |> process(user, minted_token)
      {:error, code} ->
        {:error, code}
    end
  end

  defp fetch_user_and_minted_token(provider_user_id, symbol) do
    RecordFetcher.fetch_user_and_minted_token(provider_user_id, symbol)
  end

  defp load_balances({:ok, user, minted_token}, type) do
    BalanceLoader.load(user, minted_token, type)
  end
  defp load_balances({:error, code}, _type), do: {:error, code}

  defp format({minted_token, from, to}, amount, metadata) do
    Formatter.format(from, to, minted_token, amount, metadata)
  end

  defp insert(attrs) do
    attrs |> Transaction.serialize() |> Entry.insert()
  end

  defp process({:ok, _trans}, user, minted_token), do: {:ok, user, minted_token}
  defp process({:error, code, description}, _user, _minted_token) do
    {:error, code, description}
  end
end
