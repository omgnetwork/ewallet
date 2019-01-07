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

defmodule AdminAPI.V1.KeyViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.KeyView
  alias EWallet.Web.Paginator
  alias EWalletDB.Helpers.Preloader
  alias Utils.Helpers.DateFormatter

  describe "render/2" do
    test "renders key.json with correct response format" do
      key = :key |> insert() |> Preloader.preload(:account)

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "key",
          id: key.id,
          access_key: key.access_key,
          secret_key: key.secret_key,
          account_id: key.account.id,
          expired: !key.enabled,
          enabled: key.enabled,
          created_at: DateFormatter.to_iso8601(key.inserted_at),
          updated_at: DateFormatter.to_iso8601(key.updated_at),
          deleted_at: DateFormatter.to_iso8601(key.deleted_at)
        }
      }

      assert KeyView.render("key.json", %{key: key}) == expected
    end

    test "renders keys.json with correct response format" do
      key1 = :key |> insert() |> Preloader.preload(:account)
      key2 = :key |> insert() |> Preloader.preload(:account)

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
        version: @expected_version,
        success: true,
        data: %{
          object: "list",
          data: [
            %{
              object: "key",
              id: key1.id,
              access_key: key1.access_key,
              secret_key: key1.secret_key,
              account_id: key1.account.id,
              expired: !key1.enabled,
              enabled: key1.enabled,
              created_at: DateFormatter.to_iso8601(key1.inserted_at),
              updated_at: DateFormatter.to_iso8601(key1.updated_at),
              deleted_at: DateFormatter.to_iso8601(key1.deleted_at)
            },
            %{
              object: "key",
              id: key2.id,
              access_key: key2.access_key,
              secret_key: key2.secret_key,
              account_id: key2.account.id,
              expired: !key2.enabled,
              enabled: key2.enabled,
              created_at: DateFormatter.to_iso8601(key2.inserted_at),
              updated_at: DateFormatter.to_iso8601(key2.updated_at),
              deleted_at: DateFormatter.to_iso8601(key2.deleted_at)
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

      assert KeyView.render("keys.json", %{keys: paginator}) == expected
    end

    test "renders empty_response.json with correct structure" do
      expected = %{
        version: @expected_version,
        success: true,
        data: %{}
      }

      assert KeyView.render("empty_response.json") == expected
    end
  end
end
