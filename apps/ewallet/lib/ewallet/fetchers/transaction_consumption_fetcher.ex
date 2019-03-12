# Copyright 2018-2019 OmiseGO Pte Ltd
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

defmodule EWallet.TransactionConsumptionFetcher do
  @moduledoc """
  Handles any kind of retrieval/fetching for the TransactionConsumptionGate.

  All functions here are only meant to load and format data related to
  transaction consumptions.
  """
  alias EWalletDB.{Transaction, TransactionConsumption}

  @spec get(String.t()) ::
          {:ok, %TransactionConsumption{}}
          | {:error, :invalid_parameter, String.t()}
  def get(nil), do: {:error, :invalid_parameter, "`id` cannot be nil"}

  def get(id) do
    %{id: id}
    |> get_by()
    |> return_consumption()
  end

  defp return_consumption(nil), do: {:error, :unauthorized}
  defp return_consumption(consumption), do: {:ok, consumption}

  @spec idempotent_fetch(String.t()) ::
          {:ok, nil}
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
