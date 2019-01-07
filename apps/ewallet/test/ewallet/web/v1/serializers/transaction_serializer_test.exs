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

defmodule EWallet.Web.V1.TransactionSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias Ecto.Association.NotLoaded
  alias Utils.Helpers.DateFormatter
  alias EWallet.Web.V1.{AccountSerializer, TokenSerializer, TransactionSerializer, UserSerializer}
  alias Utils.Helpers.Assoc
  alias EWalletDB.{Repo, Token}

  describe "serialize/1 for single transaction" do
    test "serializes into correct V1 transaction format" do
      transaction =
        insert(:transaction) |> Repo.preload([:from_user, :from_account, :to_user, :to_account])

      from_token = Token.get_by(uuid: transaction.from_token_uuid)
      to_token = Token.get_by(uuid: transaction.to_token_uuid)

      expected = %{
        object: "transaction",
        id: transaction.id,
        idempotency_token: transaction.idempotency_token,
        from: %{
          object: "transaction_source",
          address: transaction.from,
          amount: transaction.from_amount,
          account: AccountSerializer.serialize(transaction.from_account),
          account_id: Assoc.get(transaction, [:from_account, :id]),
          user: UserSerializer.serialize(transaction.from_user),
          user_id: Assoc.get(transaction, [:from_user, :id]),
          token_id: from_token.id,
          token: TokenSerializer.serialize(from_token)
        },
        to: %{
          object: "transaction_source",
          address: transaction.to,
          amount: transaction.to_amount,
          account: AccountSerializer.serialize(transaction.to_account),
          account_id: Assoc.get(transaction, [:to_account, :id]),
          user: UserSerializer.serialize(transaction.to_user),
          user_id: Assoc.get(transaction, [:to_user, :id]),
          token_id: to_token.id,
          token: TokenSerializer.serialize(to_token)
        },
        exchange: %{
          object: "exchange",
          rate: nil,
          calculated_at: nil,
          exchange_pair: nil,
          exchange_pair_id: nil,
          exchange_account: nil,
          exchange_account_id: nil,
          exchange_wallet: nil,
          exchange_wallet_address: nil
        },
        metadata: %{some: "metadata"},
        encrypted_metadata: %{},
        status: transaction.status,
        error_code: nil,
        error_description: nil,
        created_at: DateFormatter.to_iso8601(transaction.inserted_at),
        updated_at: DateFormatter.to_iso8601(transaction.updated_at)
      }

      assert TransactionSerializer.serialize(transaction) == expected
    end

    test "serializes to nil if the transaction is not loaded" do
      assert TransactionSerializer.serialize(%NotLoaded{}) == nil
    end

    test "serializes the error description properly if nil" do
      transaction =
        insert(
          :transaction,
          error_code: "exchange_invalid_rate"
        )

      serialized = TransactionSerializer.serialize(transaction)
      assert serialized[:error_code] == "exchange:invalid_rate"
      assert serialized[:error_description] == "The exchange is attempted with an invalid rate."
    end

    test "serializes the error description properly" do
      transaction =
        insert(
          :transaction,
          error_code: "insufficient_funds",
          error_description: "Some description."
        )

      serialized = TransactionSerializer.serialize(transaction)
      assert serialized[:error_code] == "transaction:insufficient_funds"
      assert serialized[:error_description] == "Some description."
    end

    test "serializes the error data properly" do
      token = insert(:token)

      transaction =
        insert(
          :transaction,
          error_code: "insufficient_funds",
          error_data: %{
            "address" => "123",
            "amount_to_debit" => 100_000,
            "current_amount" => 0,
            "token_id" => token.id
          }
        )

      serialized = TransactionSerializer.serialize(transaction)
      assert serialized[:error_code] == "transaction:insufficient_funds"

      assert serialized[:error_description] ==
               "The specified wallet (123) does not contain enough funds. Available: 0 #{token.id} - Attempted debit: 1000 #{
                 token.id
               }"
    end
  end
end
