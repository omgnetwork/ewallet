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

defmodule AdminAPI.V1.ProviderAuth.APIKeyControllerTest do
  use AdminAPI.ConnCase, async: true
  alias Utils.Helpers.DateFormatter
  alias EWalletDB.Helpers.Preloader
  alias EWalletDB.{Account, APIKey, Repo}

  describe "/api_key.all" do
    test "responds with a list of api keys when no params are given" do
      [api_key1, api_key2] = APIKey |> ensure_num_records(2) |> Preloader.preload(:account)

      assert provider_request("/api_key.all") ==
               %{
                 "version" => "1",
                 "success" => true,
                 "data" => %{
                   "object" => "list",
                   "data" => [
                     %{
                       "object" => "api_key",
                       "id" => api_key1.id,
                       "key" => api_key1.key,
                       "account_id" => api_key1.account.id,
                       "owner_app" => api_key1.owner_app,
                       "expired" => false,
                       "enabled" => true,
                       "created_at" => DateFormatter.to_iso8601(api_key1.inserted_at),
                       "updated_at" => DateFormatter.to_iso8601(api_key1.updated_at),
                       "deleted_at" => DateFormatter.to_iso8601(api_key1.deleted_at)
                     },
                     %{
                       "object" => "api_key",
                       "id" => api_key2.id,
                       "key" => api_key2.key,
                       "account_id" => api_key2.account.id,
                       "owner_app" => api_key2.owner_app,
                       "expired" => false,
                       "enabled" => true,
                       "created_at" => DateFormatter.to_iso8601(api_key2.inserted_at),
                       "updated_at" => DateFormatter.to_iso8601(api_key2.updated_at),
                       "deleted_at" => DateFormatter.to_iso8601(api_key2.deleted_at)
                     }
                   ],
                   "pagination" => %{
                     "current_page" => 1,
                     "per_page" => 10,
                     "is_first_page" => true,
                     "is_last_page" => true,
                     "count" => 2
                   }
                 }
               }
    end

    test "responds with a list of api keys when given pagination params" do
      [_, api_key] = insert_list(2, :api_key, owner_app: "test_provider_auth_api_key_all")

      # Note that per_page is set to only a single record
      attrs = %{
        match_all: [
          %{
            field: "owner_app",
            comparator: "eq",
            value: "test_provider_auth_api_key_all"
          }
        ],
        page: 1,
        per_page: 1,
        sort_by: "created_at",
        sort_dir: "desc"
      }

      assert provider_request("/api_key.all", attrs) ==
               %{
                 "version" => "1",
                 "success" => true,
                 "data" => %{
                   "object" => "list",
                   "data" => [
                     %{
                       "object" => "api_key",
                       "id" => api_key.id,
                       "key" => api_key.key,
                       "account_id" => api_key.account.id,
                       "owner_app" => api_key.owner_app,
                       "expired" => false,
                       "enabled" => true,
                       "created_at" => DateFormatter.to_iso8601(api_key.inserted_at),
                       "updated_at" => DateFormatter.to_iso8601(api_key.updated_at),
                       "deleted_at" => DateFormatter.to_iso8601(api_key.deleted_at)
                     }
                   ],
                   "pagination" => %{
                     "current_page" => 1,
                     "per_page" => 1,
                     "is_first_page" => true,
                     "is_last_page" => false,
                     "count" => 1
                   }
                 }
               }
    end

    test_supports_match_any("/api_key.all", :provider_auth, :api_key, :key)
    test_supports_match_all("/api_key.all", :provider_auth, :api_key, :key)
  end

  describe "/api_key.create" do
    test "responds with an API key on success" do
      response = provider_request("/api_key.create", %{})
      api_key = get_last_inserted(APIKey)

      assert response == %{
               "version" => "1",
               "success" => true,
               "data" => %{
                 "object" => "api_key",
                 "id" => api_key.id,
                 "key" => api_key.key,
                 "account_id" => Account.get_master_account().id,
                 "owner_app" => "ewallet_api",
                 "expired" => false,
                 "enabled" => true,
                 "created_at" => DateFormatter.to_iso8601(api_key.inserted_at),
                 "updated_at" => DateFormatter.to_iso8601(api_key.updated_at),
                 "deleted_at" => DateFormatter.to_iso8601(api_key.deleted_at)
               }
             }
    end

    test "generates an activity log" do
      timestamp = DateTime.utc_now()
      response = provider_request("/api_key.create", %{})

      assert response["success"] == true
      api_key = get_last_inserted(APIKey)
      account = Account.get_master_account()

      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: get_test_key(),
        target: api_key,
        changes: %{
          "account_uuid" => account.uuid,
          "key" => response["data"]["key"],
          "owner_app" => "ewallet_api"
        },
        encrypted_changes: %{}
      )
    end
  end

  describe "/api_key.update" do
    test "disables the API key" do
      api_key = :api_key |> insert() |> Repo.preload(:account)
      assert api_key.enabled == true

      response =
        provider_request("/api_key.update", %{
          id: api_key.id,
          expired: true
        })

      assert response["data"]["id"] == api_key.id
      assert response["data"]["expired"] == true
      assert response["data"]["enabled"] == false
    end

    test "enables the API key" do
      api_key = :api_key |> insert(enabled: false) |> Repo.preload(:account)
      assert api_key.enabled == false

      response =
        provider_request("/api_key.update", %{
          id: api_key.id,
          expired: false
        })

      assert response["data"]["id"] == api_key.id
      assert response["data"]["expired"] == false
      assert response["data"]["enabled"] == true
    end

    test "does not update any other fields" do
      api_key = :api_key |> insert() |> Repo.preload(:account)
      assert api_key.enabled == true

      response =
        provider_request("/api_key.update", %{
          id: api_key.id,
          expired: true,
          owner_app: "something",
          key: "some_key",
          account_id: "random"
        })

      updated = APIKey.get(api_key.id)

      assert response == %{
               "version" => "1",
               "success" => true,
               "data" => %{
                 "object" => "api_key",
                 "id" => updated.id,
                 "key" => api_key.key,
                 "expired" => true,
                 "enabled" => false,
                 "account_id" => api_key.account.id,
                 "owner_app" => api_key.owner_app,
                 "created_at" => DateFormatter.to_iso8601(api_key.inserted_at),
                 "updated_at" => DateFormatter.to_iso8601(updated.updated_at),
                 "deleted_at" => DateFormatter.to_iso8601(api_key.deleted_at)
               }
             }
    end

    test "generates an activity log" do
      api_key = :api_key |> insert() |> Repo.preload(:account)
      timestamp = DateTime.utc_now()

      response =
        provider_request("/api_key.update", %{
          id: api_key.id,
          expired: true
        })

      assert response["success"] == true

      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: get_test_key(),
        target: api_key,
        changes: %{
          "enabled" => false
        },
        encrypted_changes: %{}
      )
    end
  end

  describe "/api_key.enable_or_disable" do
    test "disables the API key" do
      api_key = :api_key |> insert() |> Repo.preload(:account)
      assert api_key.enabled == true

      response =
        provider_request("/api_key.enable_or_disable", %{
          id: api_key.id,
          enabled: false
        })

      assert response["data"]["id"] == api_key.id
      assert response["data"]["enabled"] == false
    end

    test "disabling an API key twice doesn't re-enable it" do
      api_key = :api_key |> insert() |> Repo.preload(:account)
      assert api_key.enabled == true

      response =
        provider_request("/api_key.enable_or_disable", %{
          id: api_key.id,
          enabled: false
        })

      assert response["data"]["id"] == api_key.id
      assert response["data"]["enabled"] == false

      response =
        provider_request("/api_key.enable_or_disable", %{
          id: api_key.id,
          enabled: false
        })

      assert response["data"]["id"] == api_key.id
      assert response["data"]["enabled"] == false
    end

    test "enables the API key" do
      api_key = :api_key |> insert(enabled: false) |> Repo.preload(:account)
      assert api_key.enabled == false

      response =
        provider_request("/api_key.enable_or_disable", %{
          id: api_key.id,
          enabled: true
        })

      assert response["data"]["id"] == api_key.id
      assert response["data"]["enabled"] == true
    end

    test "generates an activity log" do
      api_key = :api_key |> insert() |> Repo.preload(:account)
      timestamp = DateTime.utc_now()

      response =
        provider_request("/api_key.enable_or_disable", %{
          id: api_key.id,
          enabled: false
        })

      assert response["success"] == true

      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: get_test_key(),
        target: api_key,
        changes: %{
          "enabled" => false
        },
        encrypted_changes: %{}
      )
    end
  end

  describe "/api_key.delete" do
    test "responds with an empty success if provided a valid id" do
      api_key = insert(:api_key)
      response = provider_request("/api_key.delete", %{id: api_key.id})

      assert response == %{
               "version" => "1",
               "success" => true,
               "data" => %{}
             }
    end

    test "responds with an error if the provided id is not found" do
      response = provider_request("/api_key.delete", %{id: "wrong_id"})

      assert response == %{
               "version" => "1",
               "success" => false,
               "data" => %{
                 "code" => "api_key:not_found",
                 "description" => "The API key could not be found.",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test "responds with an error if the user is not authorized to delete the API key" do
      api_key = insert(:api_key)
      key = insert(:key)

      attrs = %{id: api_key.id}
      opts = [access_key: key.access_key, secret_key: key.secret_key]
      response = provider_request("/api_key.delete", attrs, opts)

      assert response ==
               %{
                 "version" => "1",
                 "success" => false,
                 "data" => %{
                   "code" => "unauthorized",
                   "description" => "You are not allowed to perform the requested operation.",
                   "messages" => nil,
                   "object" => "error"
                 }
               }
    end

    test "generates an activity log" do
      api_key = insert(:api_key)
      timestamp = DateTime.utc_now()
      response = provider_request("/api_key.delete", %{id: api_key.id})

      assert response["success"] == true

      api_key = Repo.get_by(APIKey, %{id: api_key.id})
      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: get_test_key(),
        target: api_key,
        changes: %{"deleted_at" => DateFormatter.to_iso8601(api_key.deleted_at)},
        encrypted_changes: %{}
      )
    end
  end
end
