defmodule EWallet.TransactionConsumptionFetcher do
  @moduledoc """
  Handles any kind of retrieval/fetching for the TransactionConsumptionGate.

  All functions here are only meant to load and format data related to
  transaction consumptions.
  """
  alias EWalletDB.{TransactionConsumption, Transaction}

  @spec get(String.t()) ::
          {:ok, %TransactionConsumption{}}
          | {:error, :transaction_consumption_not_found}
  def get(nil), do: {:error, :transaction_consumption_not_found}

  def get(id) do
    %{id: id}
    |> get_by()
    |> return_consumption()
  end

  defp return_consumption(nil), do: {:error, :transaction_consumption_not_found}
  defp return_consumption(consumption), do: {:ok, consumption}

  @spec idempotent_fetch(String.t()) ::
          {:ok, %TransactionConsumption{}}
          | {:idempotent_call, %TransactionConsumption{}}
          | {:error, %TransactionConsumption{}, atom(), String.t()}
          | {:error, %TransactionConsumption{}, String.t(), String.t()}
  def idempotent_fetch(idempotency_token) do
    %{idempotency_token: idempotency_token}
    |> get_by()
    |> return_idempotent()
  end

  defp get_by(attrs) do
    TransactionConsumption.get_by(
      attrs,
      preload: [
        :account,
        :user,
        :wallet,
        :token,
        :transaction_request,
        :transaction,
        :exchange_account,
        :exchange_wallet
      ]
    )
  end

  defp return_idempotent(nil), do: {:ok, nil}

  defp return_idempotent(%TransactionConsumption{transaction: nil} = consumption) do
    {:idempotent_call, consumption}
  end

  defp return_idempotent(%TransactionConsumption{transaction: transaction} = consumption) do
    return_transaction_result(consumption, failed_transaction: Transaction.failed?(transaction))
  end

  defp return_transaction_result(consumption, failed_transaction: true) do
    {code, description} = Transaction.get_error(consumption.transaction)
    {:error, consumption, code, description}
  end

  defp return_transaction_result(consumption, failed_transaction: false) do
    {:idempotent_call, consumption}
  end
end
