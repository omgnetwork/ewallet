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

defmodule EWallet.Web.V1.KeySerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.KeySerializer
  alias Utils.Helpers.DateFormatter

  describe "serialize/1" do
    test "serializes a key into the correct response format" do
      key = insert(:key)

      expected = %{
        object: "key",
        id: key.id,
        name: key.name,
        access_key: key.access_key,
        secret_key: key.secret_key,
        account_id: nil,
        expired: !key.enabled,
        enabled: key.enabled,
        global_role: key.global_role,
        created_at: DateFormatter.to_iso8601(key.inserted_at),
        updated_at: DateFormatter.to_iso8601(key.updated_at),
        deleted_at: DateFormatter.to_iso8601(key.deleted_at)
      }

      assert KeySerializer.serialize(key) == expected
    end

    test "serializes to nil if the key is not loaded" do
      assert KeySerializer.serialize(%NotLoaded{}) == nil
    end

    test "serializes a key paginator into a list object" do
      key1 = insert(:key)
      key2 = insert(:key)

      paginator = %Paginator{
        data: [key1, key2],
        pagination: %{
          current_page: 1,
          per_page: 10,
          is_first_page: true,
          is_last_page: true
        }
      }

      expected = %{
        object: "list",
        data: [
          %{
            object: "key",
            id: key1.id,
            name: key1.name,
            access_key: key1.access_key,
            secret_key: key1.secret_key,
            account_id: nil,
            expired: !key1.enabled,
            enabled: key1.enabled,
            global_role: key1.global_role,
            created_at: DateFormatter.to_iso8601(key1.inserted_at),
            updated_at: DateFormatter.to_iso8601(key1.updated_at),
            deleted_at: DateFormatter.to_iso8601(key1.deleted_at)
          },
          %{
            object: "key",
            id: key2.id,
            name: key2.name,
            access_key: key2.access_key,
            secret_key: key2.secret_key,
            account_id: nil,
            expired: !key2.enabled,
            enabled: key2.enabled,
            global_role: key2.global_role,
            created_at: DateFormatter.to_iso8601(key2.inserted_at),
            updated_at: DateFormatter.to_iso8601(key2.updated_at),
            deleted_at: DateFormatter.to_iso8601(key2.deleted_at)
          }
        ],
        pagination: %{
          current_page: 1,
          per_page: 10,
          is_first_page: true,
          is_last_page: true
        }
      }

      assert KeySerializer.serialize(paginator) == expected
    end
  end
end
