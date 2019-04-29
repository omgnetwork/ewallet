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

defmodule EWallet.Web.V1.TransactionSerializer do
  @moduledoc """
  Serializes token(s) into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded

  alias EWallet.Web.V1.{
    AccountSerializer,
    ErrorHandler,
    ExchangePairSerializer,
    PaginatorSerializer,
    TokenSerializer,
    UserSerializer,
    WalletSerializer
  }

  alias EWallet.Web.Paginator
  alias Utils.Helpers.{Assoc, DateFormatter}
  alias EWalletDB.Transaction

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(%Transaction{} = transaction) do
    error = build_error(transaction)

    %{
      object: "transaction",
      id: transaction.id,
      idempotency_token: transaction.idempotency_token,
      from: %{
        object: "transaction_source",
        user_id: Assoc.get(transaction, [:from_user, :id]),
        user: UserSerializer.serialize(transaction.from_user),
        account_id: Assoc.get(transaction, [:from_account, :id]),
        account: AccountSerializer.serialize(transaction.from_account),
        address: transaction.from,
        amount: transaction.from_amount,
        token_id: Assoc.get(transaction, [:from_token, :id]),
        token: TokenSerializer.serialize(transaction.from_token)
      },
      to: %{
        object: "transaction_source",
        user_id: Assoc.get(transaction, [:to_user, :id]),
        user: UserSerializer.serialize(transaction.to_user),
        account_id: Assoc.get(transaction, [:to_account, :id]),
        account: AccountSerializer.serialize(transaction.to_account),
        address: transaction.to,
        amount: transaction.to_amount,
        token_id: Assoc.get(transaction, [:to_token, :id]),
        token: TokenSerializer.serialize(transaction.to_token)
      },
      exchange: %{
        object: "exchange",
        rate: transaction.rate,
        calculated_at: DateFormatter.to_iso8601(transaction.calculated_at),
        exchange_pair_id: Assoc.get(transaction, [:exchange_pair, :id]),
        exchange_pair: ExchangePairSerializer.serialize(transaction.exchange_pair),
        exchange_account_id: Assoc.get(transaction, [:exchange_account, :id]),
        exchange_account: AccountSerializer.serialize(transaction.exchange_account),
        exchange_wallet_address: Assoc.get(transaction, [:exchange_wallet, :address]),
        exchange_wallet: WalletSerializer.serialize(transaction.exchange_wallet)
      },
      metadata: transaction.metadata || %{},
      encrypted_metadata: transaction.encrypted_metadata || %{},
      status: transaction.status,
      error_code: error[:code],
      error_description: error[:description],
      created_at: DateFormatter.to_iso8601(transaction.inserted_at),
      updated_at: DateFormatter.to_iso8601(transaction.updated_at)
    }
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil

  defp build_error(%Transaction{error_code: nil}), do: nil

  defp build_error(%Transaction{error_code: code, error_description: desc, error_data: data})
       when not is_nil(data) or not is_nil(desc) do
    ErrorHandler.build_error(code, data || desc, ErrorHandler.errors())
  end

  defp build_error(%Transaction{error_code: code}) do
    ErrorHandler.build_error(code, ErrorHandler.errors())
  end
end
