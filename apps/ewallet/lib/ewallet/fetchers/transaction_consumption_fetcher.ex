defmodule EWallet.TransactionConsumptionFetcher do
  @moduledoc """
  Handles any kind of retrieval/fetching for the TransactionConsumptionGate.

  All functions here are only meant to load and format data related to
  transaction consumptions.
  """
  alias EWalletDB.{TransactionConsumption, Transfer}

  @spec get(UUID.t()) ::
          {:ok, TransactionConsumption.t()}
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
          {:ok, TransactionConsumption.t()}
          | {:idempotent_call, TransactionConsumption.t()}
          | {:error, TransactionConsumption.t(), Atom.t(), String.t()}
          | {:error, TransactionConsumption.t(), String.t(), String.t()}
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
        :transfer
      ]
    )
  end

  defp return_idempotent(nil), do: {:ok, nil}

  defp return_idempotent(%TransactionConsumption{transfer: nil} = consumption) do
    {:idempotent_call, consumption}
  end

  defp return_idempotent(%TransactionConsumption{transfer: transfer} = consumption) do
    return_transfer_result(consumption, failed_transfer: Transfer.failed?(transfer))
  end

  defp return_transfer_result(consumption, failed_transfer: true) do
    {code, description} = Transfer.get_error(consumption.transfer)
    {:error, consumption, code, description}
  end

  defp return_transfer_result(consumption, failed_transfer: false) do
    {:idempotent_call, consumption}
  end
end
