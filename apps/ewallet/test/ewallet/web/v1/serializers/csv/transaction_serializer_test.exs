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

defmodule EWallet.Web.V1.CSV.TransactionSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.CSV.TransactionSerializer
  alias Utils.Helpers.{Assoc, DateFormatter}

  describe "serialize/1 for a single transaction" do
    test "serializes into correct V1 transaction format" do
      transaction = build(:transaction)

      expected = %{
        id: transaction.id,
        idempotency_token: transaction.idempotency_token,
        from_user_id: Assoc.get(transaction, [:from_user, :id]),
        from_account_id: Assoc.get(transaction, [:from_account, :id]),
        from_address: transaction.from,
        from_amount: transaction.from_amount,
        from_token_id: Assoc.get(transaction, [:from_token, :id]),
        to_user_id: Assoc.get(transaction, [:to_user, :id]),
        to_account_id: Assoc.get(transaction, [:to_account, :id]),
        to_address: transaction.to,
        to_amount: transaction.to_amount,
        to_token_id: Assoc.get(transaction, [:to_token, :id]),
        exchange_rate: transaction.rate,
        exchange_rate_calculated_at: DateFormatter.to_iso8601(transaction.calculated_at),
        exchange_pair_id: Assoc.get(transaction, [:exchange_pair, :id]),
        exchange_account_id: Assoc.get(transaction, [:exchange_account, :id]),
        exchange_wallet_address: Assoc.get(transaction, [:exchange_wallet, :address]),
        metadata: Poison.encode!(transaction.metadata || %{}),
        encrypted_metadata: Poison.encode!(transaction.encrypted_metadata || %{}),
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

    test "serializes nil to nil" do
      assert TransactionSerializer.serialize(nil) == nil
    end
  end

  describe "serialize/1 for an transaction paginator" do
    test "serialize into list of V1 transaction" do
      transaction_1 = build(:transaction)
      transaction_2 = build(:transaction)

      paginator = %Paginator{
        data: [transaction_1, transaction_2],
        pagination: %{
          current_page: 9,
          per_page: 7,
          is_first_page: false,
          is_last_page: true
        }
      }

      expected = %{
        object: "list",
        data: [
          %{
            id: transaction_1.id,
            idempotency_token: transaction_1.idempotency_token,
            from_user_id: Assoc.get(transaction_1, [:from_user, :id]),
            from_account_id: Assoc.get(transaction_1, [:from_account, :id]),
            from_address: transaction_1.from,
            from_amount: transaction_1.from_amount,
            from_token_id: Assoc.get(transaction_1, [:from_token, :id]),
            to_user_id: Assoc.get(transaction_1, [:to_user, :id]),
            to_account_id: Assoc.get(transaction_1, [:to_account, :id]),
            to_address: transaction_1.to,
            to_amount: transaction_1.to_amount,
            to_token_id: Assoc.get(transaction_1, [:to_token, :id]),
            exchange_rate: transaction_1.rate,
            exchange_rate_calculated_at: DateFormatter.to_iso8601(transaction_1.calculated_at),
            exchange_pair_id: Assoc.get(transaction_1, [:exchange_pair, :id]),
            exchange_account_id: Assoc.get(transaction_1, [:exchange_account, :id]),
            exchange_wallet_address: Assoc.get(transaction_1, [:exchange_wallet, :address]),
            metadata: Poison.encode!(transaction_1.metadata || %{}),
            encrypted_metadata: Poison.encode!(transaction_1.encrypted_metadata || %{}),
            status: transaction_1.status,
            error_code: nil,
            error_description: nil,
            created_at: DateFormatter.to_iso8601(transaction_1.inserted_at),
            updated_at: DateFormatter.to_iso8601(transaction_1.updated_at)
          },
          %{
            id: transaction_2.id,
            idempotency_token: transaction_2.idempotency_token,
            from_user_id: Assoc.get(transaction_2, [:from_user, :id]),
            from_account_id: Assoc.get(transaction_2, [:from_account, :id]),
            from_address: transaction_2.from,
            from_amount: transaction_2.from_amount,
            from_token_id: Assoc.get(transaction_2, [:from_token, :id]),
            to_user_id: Assoc.get(transaction_2, [:to_user, :id]),
            to_account_id: Assoc.get(transaction_2, [:to_account, :id]),
            to_address: transaction_2.to,
            to_amount: transaction_2.to_amount,
            to_token_id: Assoc.get(transaction_2, [:to_token, :id]),
            exchange_rate: transaction_2.rate,
            exchange_rate_calculated_at: DateFormatter.to_iso8601(transaction_2.calculated_at),
            exchange_pair_id: Assoc.get(transaction_2, [:exchange_pair, :id]),
            exchange_account_id: Assoc.get(transaction_2, [:exchange_account, :id]),
            exchange_wallet_address: Assoc.get(transaction_2, [:exchange_wallet, :address]),
            metadata: Poison.encode!(transaction_2.metadata || %{}),
            encrypted_metadata: Poison.encode!(transaction_2.encrypted_metadata || %{}),
            status: transaction_2.status,
            error_code: nil,
            error_description: nil,
            created_at: DateFormatter.to_iso8601(transaction_2.inserted_at),
            updated_at: DateFormatter.to_iso8601(transaction_2.updated_at)
          }
        ],
        pagination: %{
          current_page: 9,
          per_page: 7,
          is_first_page: false,
          is_last_page: true
        }
      }

      assert TransactionSerializer.serialize(paginator) == expected
    end
  end
end
