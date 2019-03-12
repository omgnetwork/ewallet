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

defmodule EWallet.Web.V1.TransactionConsumptionSerializer do
  @moduledoc """
  Serializes transaction request consumption data into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.Paginator

  alias EWallet.Web.V1.{
    AccountSerializer,
    PaginatorSerializer,
    TokenSerializer,
    TransactionRequestSerializer,
    TransactionSerializer,
    UserSerializer,
    WalletSerializer
  }

  alias Utils.Helpers.{Assoc, DateFormatter}
  alias EWalletDB.TransactionConsumption

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(%TransactionConsumption{} = consumption) do
    final_consumption_amount = TransactionConsumption.get_final_amount(consumption)
    final_request_amount = get_final_request_amount(consumption, final_consumption_amount)

    %{
      object: "transaction_consumption",
      id: consumption.id,
      socket_topic: "transaction_consumption:#{consumption.id}",
      amount: consumption.amount,
      estimated_request_amount: consumption.estimated_request_amount,
      estimated_consumption_amount: consumption.estimated_consumption_amount,
      finalized_request_amount: final_request_amount,
      finalized_consumption_amount: final_consumption_amount,
      token_id: consumption.token.id,
      token: TokenSerializer.serialize(consumption.token),
      correlation_id: consumption.correlation_id,
      idempotency_token: consumption.idempotency_token,
      transaction_id: Assoc.get(consumption, [:transaction, :id]),
      transaction: TransactionSerializer.serialize(consumption.transaction),
      user_id: Assoc.get(consumption, [:user, :id]),
      user: UserSerializer.serialize(consumption.user),
      account_id: Assoc.get(consumption, [:account, :id]),
      account: AccountSerializer.serialize(consumption.account),
      exchange_account_id: Assoc.get(consumption, [:exchange_account, :id]),
      exchange_account: AccountSerializer.serialize(consumption.exchange_account),
      exchange_wallet_address: Assoc.get(consumption, [:exchange_wallet, :address]),
      exchange_wallet: WalletSerializer.serialize_without_balances(consumption.exchange_wallet),
      transaction_request_id: Assoc.get(consumption, [:transaction_request, :id]),
      transaction_request:
        TransactionRequestSerializer.serialize(consumption.transaction_request),
      address: consumption.wallet_address,
      metadata: consumption.metadata || %{},
      encrypted_metadata: consumption.encrypted_metadata || %{},
      expiration_date: DateFormatter.to_iso8601(consumption.expiration_date),
      status: consumption.status,
      approved_at: DateFormatter.to_iso8601(consumption.approved_at),
      rejected_at: DateFormatter.to_iso8601(consumption.rejected_at),
      cancelled_at: DateFormatter.to_iso8601(consumption.cancelled_at),
      confirmed_at: DateFormatter.to_iso8601(consumption.confirmed_at),
      failed_at: DateFormatter.to_iso8601(consumption.failed_at),
      expired_at: DateFormatter.to_iso8601(consumption.expired_at),
      created_at: DateFormatter.to_iso8601(consumption.inserted_at)
    }
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil

  defp get_final_request_amount(_consumption, nil), do: nil

  defp get_final_request_amount(consumption, _amount) do
    consumption.estimated_request_amount
  end
end
