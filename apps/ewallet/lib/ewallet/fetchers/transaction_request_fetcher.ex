# Copyright 2018 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EWallet.TransactionRequestFetcher do
  @moduledoc """
  Handles any kind of retrieval/fetching for the TransactionRequestGate and the
  TransactionConsumptionGate.

  All functions here are only meant to load and format data related to
  transaction requests.
  """
  alias EWallet.Web.V1.TransactionRequestOverlay
  alias EWalletDB.TransactionRequest

  @spec get(String.t()) :: {:ok, %TransactionRequest{}} | {:error, :transaction_request_not_found}
  def get(transaction_request_id) do
    transaction_request_id
    |> TransactionRequest.get(preload: TransactionRequestOverlay.default_preload_assocs())
    |> handle_request_existence()
  end

  defp handle_request_existence(nil), do: {:error, :transaction_request_not_found}
  defp handle_request_existence(request), do: {:ok, request}

  @spec get_with_lock(String.t()) ::
          {:ok, %TransactionRequest{}}
          | {:error, :transaction_request_not_found}
  def get_with_lock(transaction_request_id) do
    request =
      TransactionRequest.get_with_lock(
        transaction_request_id,
        TransactionRequestOverlay.default_preload_assocs()
      )

    case request do
      nil -> {:error, :transaction_request_not_found}
      request -> {:ok, request}
    end
  end
end
