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

defmodule EWallet.Web.V1.CategorySerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.{Date, Paginator}
  alias EWallet.Web.V1.{AccountSerializer, CategorySerializer}

  describe "CategorySerializer.serialize/1" do
    test "serializes a category into V1 response format" do
      category = :category |> insert() |> Repo.preload([:accounts])

      expected = %{
        object: "category",
        id: category.id,
        name: category.name,
        description: category.description,
        account_ids: AccountSerializer.serialize(category.accounts, :id),
        accounts: AccountSerializer.serialize(category.accounts),
        created_at: Date.to_iso8601(category.inserted_at),
        updated_at: Date.to_iso8601(category.updated_at)
      }

      assert CategorySerializer.serialize(category) == expected
    end

    test "serializes a category paginator into a list object" do
      category1 = :category |> insert() |> Repo.preload([:accounts])
      category2 = :category |> insert() |> Repo.preload([:accounts])

      paginator = %Paginator{
        data: [category1, category2],
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
            object: "category",
            id: category1.id,
            name: category1.name,
            description: category1.description,
            account_ids: AccountSerializer.serialize(category1.accounts, :id),
            accounts: AccountSerializer.serialize(category1.accounts),
            created_at: Date.to_iso8601(category1.inserted_at),
            updated_at: Date.to_iso8601(category1.updated_at)
          },
          %{
            object: "category",
            id: category2.id,
            name: category2.name,
            description: category2.description,
            account_ids: AccountSerializer.serialize(category2.accounts, :id),
            accounts: AccountSerializer.serialize(category2.accounts),
            created_at: Date.to_iso8601(category2.inserted_at),
            updated_at: Date.to_iso8601(category2.updated_at)
          }
        ],
        pagination: %{
          current_page: 9,
          per_page: 7,
          is_first_page: false,
          is_last_page: true
        }
      }

      assert CategorySerializer.serialize(paginator) == expected
    end

    test "serializes to nil if category is not given" do
      assert CategorySerializer.serialize(nil) == nil
    end

    test "serializes to nil if category is not loaded" do
      assert CategorySerializer.serialize(%NotLoaded{}) == nil
    end

    test "serializes an empty category paginator into a list object" do
      paginator = %Paginator{
        data: [],
        pagination: %{
          current_page: 1,
          per_page: 10,
          is_first_page: true,
          is_last_page: true
        }
      }

      expected = %{
        object: "list",
        data: [],
        pagination: %{
          current_page: 1,
          per_page: 10,
          is_first_page: true,
          is_last_page: true
        }
      }

      assert CategorySerializer.serialize(paginator) == expected
    end
  end

  describe "CategorySerializer.serialize/2" do
    test "serializes categories to ids" do
      categories = [category1, category2] = insert_list(2, :account)
      assert CategorySerializer.serialize(categories, :id) == [category1.id, category2.id]
    end
  end
end
