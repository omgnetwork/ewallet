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

defmodule EWallet.Web.V1.TransactionConsumptionSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias Utils.Helpers.DateFormatter
  alias Utils.Helpers.Assoc
  alias EWalletDB.TransactionConsumption

  alias EWallet.Web.V1.{
    AccountSerializer,
    TokenSerializer,
    TransactionConsumptionSerializer,
    TransactionRequestSerializer,
    TransactionSerializer,
    UserSerializer
  }

  describe "serialize/1 for single transaction request consumption" do
    test "serializes into correct V1 transaction_request consumption format" do
      consumption = insert(:transaction_consumption)

      consumption =
        TransactionConsumption.get(
          consumption.id,
          preload: [
            :token,
            :transaction,
            :transaction_request,
            :user,
            :exchange_wallet,
            :exchange_account
          ]
        )

      expected = %{
        object: "transaction_consumption",
        id: consumption.id,
        socket_topic: "transaction_consumption:#{consumption.id}",
        status: consumption.status,
        amount: consumption.amount,
        estimated_consumption_amount: nil,
        estimated_request_amount: nil,
        finalized_request_amount: nil,
        finalized_consumption_amount: nil,
        token_id: Assoc.get(consumption, [:token, :id]),
        token: TokenSerializer.serialize(consumption.token),
        correlation_id: consumption.correlation_id,
        idempotency_token: consumption.idempotency_token,
        transaction_id: Assoc.get(consumption, [:transaction, :id]),
        transaction: TransactionSerializer.serialize(consumption.transaction),
        user_id: Assoc.get(consumption, [:user, :id]),
        user: UserSerializer.serialize(consumption.user),
        account_id: nil,
        account: AccountSerializer.serialize(consumption.account),
        exchange_wallet: nil,
        exchange_wallet_address: nil,
        exchange_account: nil,
        exchange_account_id: nil,
        transaction_request_id: Assoc.get(consumption, [:transaction_request, :id]),
        transaction_request:
          TransactionRequestSerializer.serialize(consumption.transaction_request),
        address: consumption.wallet_address,
        metadata: %{},
        encrypted_metadata: %{},
        expiration_date: nil,
        approved_at: DateFormatter.to_iso8601(consumption.approved_at),
        rejected_at: DateFormatter.to_iso8601(consumption.rejected_at),
        confirmed_at: DateFormatter.to_iso8601(consumption.confirmed_at),
        failed_at: DateFormatter.to_iso8601(consumption.failed_at),
        expired_at: DateFormatter.to_iso8601(consumption.expired_at),
        created_at: DateFormatter.to_iso8601(consumption.inserted_at),
        cancelled_at: DateFormatter.to_iso8601(consumption.cancelled_at)
      }

      assert TransactionConsumptionSerializer.serialize(consumption) == expected
    end
  end
end
