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

defmodule EWallet.Web.V1.TransactionRequestSerializer do
  @moduledoc """
  Serializes transaction request data into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded

  alias EWallet.Web.V1.{
    AccountSerializer,
    PaginatorSerializer,
    TokenSerializer,
    UserSerializer,
    WalletSerializer
  }

  alias EWallet.Web.Paginator
  alias Utils.Helpers.{Assoc, DateFormatter}
  alias EWalletDB.TransactionRequest
  alias ActivityLogger.System

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(%TransactionRequest{} = transaction_request) do
    transaction_request =
      TransactionRequest.load_consumptions_count(transaction_request, %System{})

    %{
      object: "transaction_request",
      id: transaction_request.id,
      formatted_id: transaction_request.id,
      socket_topic: "transaction_request:#{transaction_request.id}",
      type: transaction_request.type,
      amount: transaction_request.amount,
      status: transaction_request.status,
      correlation_id: transaction_request.correlation_id,
      token_id: Assoc.get(transaction_request, [:token, :id]),
      token: TokenSerializer.serialize(transaction_request.token),
      address: transaction_request.wallet_address,
      user_id: Assoc.get(transaction_request, [:user, :id]),
      user: UserSerializer.serialize(transaction_request.user),
      account_id: Assoc.get(transaction_request, [:account, :id]),
      account: AccountSerializer.serialize(transaction_request.account),
      exchange_account_id: Assoc.get(transaction_request, [:exchange_account, :id]),
      exchange_account: AccountSerializer.serialize(transaction_request.exchange_account),
      exchange_wallet_address: Assoc.get(transaction_request, [:exchange_wallet, :address]),
      exchange_wallet:
        WalletSerializer.serialize_without_balances(transaction_request.exchange_wallet),
      require_confirmation: transaction_request.require_confirmation,
      current_consumptions_count: transaction_request.consumptions_count,
      max_consumptions: transaction_request.max_consumptions,
      max_consumptions_per_user: transaction_request.max_consumptions_per_user,
      consumption_lifetime: transaction_request.consumption_lifetime,
      expiration_reason: transaction_request.expiration_reason,
      allow_amount_override: transaction_request.allow_amount_override,
      metadata: transaction_request.metadata || %{},
      encrypted_metadata: transaction_request.encrypted_metadata || %{},
      expiration_date: DateFormatter.to_iso8601(transaction_request.expiration_date),
      expired_at: DateFormatter.to_iso8601(transaction_request.expired_at),
      created_at: DateFormatter.to_iso8601(transaction_request.inserted_at),
      updated_at: DateFormatter.to_iso8601(transaction_request.updated_at)
    }
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil
end
