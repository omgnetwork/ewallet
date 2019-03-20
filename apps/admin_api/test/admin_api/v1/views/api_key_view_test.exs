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

defmodule AdminAPI.V1.APIKeyViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.APIKeyView
  alias EWallet.Web.Paginator
  alias Utils.Helpers.{Assoc, DateFormatter}

  describe "render/2" do
    test "renders api_key.json with correct response format" do
      api_key = insert(:api_key)

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "api_key",
          id: api_key.id,
          name: api_key.name,
          key: api_key.key,
          creator_user_id: Assoc.get(api_key, [:creator_user, :id]),
          creator_key_id: Assoc.get(api_key, [:creator_key, :id]),
          expired: false,
          enabled: true,
          created_at: DateFormatter.to_iso8601(api_key.inserted_at),
          updated_at: DateFormatter.to_iso8601(api_key.updated_at),
          deleted_at: DateFormatter.to_iso8601(api_key.deleted_at)
        }
      }

      assert APIKeyView.render("api_key.json", %{api_key: api_key}) == expected
    end

    test "renders api_keys.json with correct response format" do
      api_key1 = insert(:api_key)
      api_key2 = insert(:api_key)

      paginator = %Paginator{
        data: [api_key1, api_key2],
        pagination: %{
          current_page: 1,
          per_page: 10,
          is_first_page: true,
          is_last_page: true
        }
      }

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "list",
          data: [
            %{
              object: "api_key",
              id: api_key1.id,
              name: api_key1.name,
              key: api_key1.key,
              creator_user_id: Assoc.get(api_key1, [:creator_user, :id]),
              creator_key_id: Assoc.get(api_key1, [:creator_key, :id]),
              expired: false,
              enabled: true,
              created_at: DateFormatter.to_iso8601(api_key1.inserted_at),
              updated_at: DateFormatter.to_iso8601(api_key1.updated_at),
              deleted_at: DateFormatter.to_iso8601(api_key1.deleted_at)
            },
            %{
              object: "api_key",
              id: api_key2.id,
              name: api_key2.name,
              key: api_key2.key,
              creator_user_id: Assoc.get(api_key2, [:creator_user, :id]),
              creator_key_id: Assoc.get(api_key2, [:creator_key, :id]),
              expired: false,
              enabled: true,
              created_at: DateFormatter.to_iso8601(api_key2.inserted_at),
              updated_at: DateFormatter.to_iso8601(api_key2.updated_at),
              deleted_at: DateFormatter.to_iso8601(api_key2.deleted_at)
            }
          ],
          pagination: %{
            per_page: 10,
            current_page: 1,
            is_first_page: true,
            is_last_page: true
          }
        }
      }

      assert APIKeyView.render("api_keys.json", %{api_keys: paginator}) == expected
    end

    test "renders empty_response.json with correct structure" do
      expected = %{
        version: @expected_version,
        success: true,
        data: %{}
      }

      assert APIKeyView.render("empty_response.json") == expected
    end
  end
end
