# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWallet.Web.V1.TransactionRequestSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias Utils.Helpers.Assoc
  alias EWalletDB.TransactionRequest

  alias EWallet.Web.V1.{
    TransactionRequestOverlay,
    AccountSerializer,
    TokenSerializer,
    TransactionRequestSerializer,
    UserSerializer
  }

  alias Utils.Helpers.DateFormatter

  describe "serialize/1 for single transaction request" do
    test "serializes into correct V1 transaction_request format" do
      request = insert(:transaction_request)

      transaction_request =
        TransactionRequest.get(
          request.id,
          preload: TransactionRequestOverlay.default_preload_assocs()
        )

      expected = %{
        object: "transaction_request",
        id: transaction_request.id,
        formatted_id: transaction_request.id,
        socket_topic: "transaction_request:#{transaction_request.id}",
        type: transaction_request.type,
        token_id: Assoc.get(transaction_request, [:token, :id]),
        token: TokenSerializer.serialize(transaction_request.token),
        amount: transaction_request.amount,
        user_id: Assoc.get(transaction_request, [:user, :id]),
        user: UserSerializer.serialize(transaction_request.user),
        account_id: Assoc.get(transaction_request, [:account, :id]),
        account: AccountSerializer.serialize(transaction_request.account),
        exchange_account: nil,
        exchange_account_id: nil,
        exchange_wallet: nil,
        exchange_wallet_address: nil,
        address: transaction_request.wallet_address,
        correlation_id: transaction_request.correlation_id,
        status: "valid",
        allow_amount_override: true,
        require_confirmation: false,
        consumption_lifetime: nil,
        metadata: %{},
        encrypted_metadata: %{},
        expiration_date: nil,
        expiration_reason: nil,
        expired_at: nil,
        max_consumptions: nil,
        max_consumptions_per_user: nil,
        current_consumptions_count: 0,
        created_at: DateFormatter.to_iso8601(transaction_request.inserted_at),
        updated_at: DateFormatter.to_iso8601(transaction_request.updated_at)
      }

      assert TransactionRequestSerializer.serialize(transaction_request) == expected
    end
  end
end
