defmodule EWallet.TransactionRequestFetcher do
  @moduledoc """
  Handles any kind of retrieval/fetching for the TransactionRequestGate and the
  TransactionConsumptionGate.

  All functions here are only meant to load and format data related to
  transaction requests.
  """
  alias EWalletDB.TransactionRequest

  @spec get(UUID.t()) :: {:ok, TransactionRequest.t()} | {:error, :transaction_request_not_found}
  def get(id) do
    id
    |> TransactionRequest.get(preload: [:token, :user, :wallet])
    |> handle_request_existence()
  end

  defp handle_request_existence(nil), do: {:error, :transaction_request_not_found}
  defp handle_request_existence(request), do: {:ok, request}

  @spec get_with_lock(UUID.t()) ::
          {:ok, TransactionRequest.t()}
          | {:error, :transaction_request_not_found}
  def get_with_lock(id) do
    request = TransactionRequest.get_with_lock(id)

    case request do
      nil -> {:error, :transaction_request_not_found}
      request -> {:ok, request}
    end
  end
end
