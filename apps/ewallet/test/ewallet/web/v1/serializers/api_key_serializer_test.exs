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

defmodule EWallet.Web.V1.APIKeySerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.APIKeySerializer
  alias Utils.Helpers.{Assoc, DateFormatter}

  describe "serialize/1" do
    test "serializes a api_key into the correct response format" do
      api_key = :api_key |> insert() |> Repo.preload([:creator_user, :creator_key])

      expected = %{
        object: "api_key",
        id: api_key.id,
        name: api_key.name,
        key: api_key.key,
        creator_user_id: Assoc.get(api_key, [:creator_user, :id]),
        creator_key_id: Assoc.get(api_key, [:creator_key, :id]),
        expired: !api_key.enabled,
        enabled: api_key.enabled,
        created_at: DateFormatter.to_iso8601(api_key.inserted_at),
        updated_at: DateFormatter.to_iso8601(api_key.updated_at),
        deleted_at: DateFormatter.to_iso8601(api_key.deleted_at)
      }

      assert APIKeySerializer.serialize(api_key) == expected
    end

    test "serializes to nil if the api_key is not loaded" do
      assert APIKeySerializer.serialize(%NotLoaded{}) == nil
    end

    test "serializes nil to nil " do
      assert APIKeySerializer.serialize(nil) == nil
    end

    test "serializes a api_key paginator into a list object" do
      api_key_1 = :api_key |> insert() |> Repo.preload([:creator_user, :creator_key])
      api_key_2 = :api_key |> insert() |> Repo.preload([:creator_user, :creator_key])

      paginator = %Paginator{
        data: [api_key_1, api_key_2],
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
            object: "api_key",
            id: api_key_1.id,
            name: api_key_1.name,
            key: api_key_1.key,
            creator_user_id: Assoc.get(api_key_1, [:creator_user, :id]),
            creator_key_id: Assoc.get(api_key_1, [:creator_key, :id]),
            expired: !api_key_1.enabled,
            enabled: api_key_1.enabled,
            created_at: DateFormatter.to_iso8601(api_key_1.inserted_at),
            updated_at: DateFormatter.to_iso8601(api_key_1.updated_at),
            deleted_at: DateFormatter.to_iso8601(api_key_1.deleted_at)
          },
          %{
            object: "api_key",
            id: api_key_2.id,
            name: api_key_2.name,
            key: api_key_2.key,
            creator_user_id: Assoc.get(api_key_2, [:creator_user, :id]),
            creator_key_id: Assoc.get(api_key_2, [:creator_key, :id]),
            expired: !api_key_2.enabled,
            enabled: api_key_2.enabled,
            created_at: DateFormatter.to_iso8601(api_key_2.inserted_at),
            updated_at: DateFormatter.to_iso8601(api_key_2.updated_at),
            deleted_at: DateFormatter.to_iso8601(api_key_2.deleted_at)
          }
        ],
        pagination: %{
          current_page: 1,
          per_page: 10,
          is_first_page: true,
          is_last_page: true
        }
      }

      assert APIKeySerializer.serialize(paginator) == expected
    end
  end
end
