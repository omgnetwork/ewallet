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

defmodule EWallet.Web.V1.MintSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.{AccountSerializer, MintSerializer, TokenSerializer, TransactionSerializer}
  alias Utils.Helpers.{Assoc, DateFormatter}

  describe "serialize/1" do
    test "serializes a mint into V1 response format" do
      mint = insert(:mint)

      expected = %{
        object: "mint",
        id: mint.id,
        description: mint.description,
        amount: mint.amount,
        confirmed: mint.confirmed,
        token_id: Assoc.get(mint, [:token, :id]),
        token: TokenSerializer.serialize(mint.token),
        account_id: Assoc.get(mint, [:account, :id]),
        account: AccountSerializer.serialize(mint.account),
        transaction_id: Assoc.get(mint, [:transaction, :id]),
        transaction: TransactionSerializer.serialize(mint.transaction),
        created_at: DateFormatter.to_iso8601(mint.inserted_at),
        updated_at: DateFormatter.to_iso8601(mint.updated_at)
      }

      assert MintSerializer.serialize(mint) == expected
    end

    test "serializes a mint list into a list object" do
      mint_1 = insert(:mint)
      mint_2 = insert(:mint)

      mint_list = [mint_1, mint_2]

      expected = [
        %{
          object: "mint",
          id: mint_1.id,
          description: mint_1.description,
          amount: mint_1.amount,
          confirmed: mint_1.confirmed,
          token_id: Assoc.get(mint_1, [:token, :id]),
          token: TokenSerializer.serialize(mint_1.token),
          account_id: Assoc.get(mint_1, [:account, :id]),
          account: AccountSerializer.serialize(mint_1.account),
          transaction_id: Assoc.get(mint_1, [:transaction, :id]),
          transaction: TransactionSerializer.serialize(mint_1.transaction),
          created_at: DateFormatter.to_iso8601(mint_1.inserted_at),
          updated_at: DateFormatter.to_iso8601(mint_1.updated_at)
        },
        %{
          object: "mint",
          id: mint_2.id,
          description: mint_2.description,
          amount: mint_2.amount,
          confirmed: mint_2.confirmed,
          token_id: Assoc.get(mint_2, [:token, :id]),
          token: TokenSerializer.serialize(mint_2.token),
          account_id: Assoc.get(mint_2, [:account, :id]),
          account: AccountSerializer.serialize(mint_2.account),
          transaction_id: Assoc.get(mint_2, [:transaction, :id]),
          transaction: TransactionSerializer.serialize(mint_2.transaction),
          created_at: DateFormatter.to_iso8601(mint_2.inserted_at),
          updated_at: DateFormatter.to_iso8601(mint_2.updated_at)
        }
      ]

      assert MintSerializer.serialize(mint_list) == expected
    end

    test "serializes a mint paginator into a paginated list object" do
      mint_1 = insert(:mint)
      mint_2 = insert(:mint)

      paginator = %Paginator{
        data: [mint_1, mint_2],
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
            object: "mint",
            id: mint_1.id,
            description: mint_1.description,
            amount: mint_1.amount,
            confirmed: mint_1.confirmed,
            token_id: Assoc.get(mint_1, [:token, :id]),
            token: TokenSerializer.serialize(mint_1.token),
            account_id: Assoc.get(mint_1, [:account, :id]),
            account: AccountSerializer.serialize(mint_1.account),
            transaction_id: Assoc.get(mint_1, [:transaction, :id]),
            transaction: TransactionSerializer.serialize(mint_1.transaction),
            created_at: DateFormatter.to_iso8601(mint_1.inserted_at),
            updated_at: DateFormatter.to_iso8601(mint_1.updated_at)
          },
          %{
            object: "mint",
            id: mint_2.id,
            description: mint_2.description,
            amount: mint_2.amount,
            confirmed: mint_2.confirmed,
            token_id: Assoc.get(mint_2, [:token, :id]),
            token: TokenSerializer.serialize(mint_2.token),
            account_id: Assoc.get(mint_2, [:account, :id]),
            account: AccountSerializer.serialize(mint_2.account),
            transaction_id: Assoc.get(mint_2, [:transaction, :id]),
            transaction: TransactionSerializer.serialize(mint_2.transaction),
            created_at: DateFormatter.to_iso8601(mint_2.inserted_at),
            updated_at: DateFormatter.to_iso8601(mint_2.updated_at)
          }
        ],
        pagination: %{
          current_page: 9,
          per_page: 7,
          is_first_page: false,
          is_last_page: true
        }
      }

      assert MintSerializer.serialize(paginator) == expected
    end

    test "serializes to nil if the mint is nil" do
      assert MintSerializer.serialize(nil) == nil
    end

    test "serializes to nil if the mint is not loaded" do
      assert MintSerializer.serialize(%NotLoaded{}) == nil
    end
  end
end
