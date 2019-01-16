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

defmodule AdminAPI.V1.AdminAuth.KeyControllerTest do
  use AdminAPI.ConnCase, async: true
  alias Utils.Helpers.DateFormatter
  alias EWalletDB.{Account, Key, Repo}

  describe "/access_key.all" do
    test "responds with a list of keys without secret keys" do
      key_1 = Key.get_by(%{access_key: @access_key}, preload: :account)
      key_2 = insert(:key, %{secret_key: "the_secret_key"})

      response = admin_user_request("/access_key.all")

      assert Enum.all?(response["data"]["data"], fn key -> key["object"] == "key" end)
      assert Enum.all?(response["data"]["data"], fn key -> key["secret_key"] == nil end)

      assert Enum.count(response["data"]["data"]) == 2

      assert Enum.any?(response["data"]["data"], fn key ->
               key["access_key"] == key_1.access_key
             end)

      assert Enum.any?(response["data"]["data"], fn key ->
               key["access_key"] == key_2.access_key
             end)
    end

    test "responds with a list of keys excluding the soft-deleted ones" do
      originator = insert(:user)
      [key1, key2, key3] = ensure_num_records(Key, 3)
      {:ok, _} = Key.delete(key2, originator)

      response = admin_user_request("/access_key.all")
      keys = response["data"]["data"]

      assert Enum.count(keys) == 2
      assert Enum.any?(keys, fn a -> a["id"] == key1.id end)
      refute Enum.any?(keys, fn a -> a["id"] == key2.id end)
      assert Enum.any?(keys, fn a -> a["id"] == key3.id end)
    end

    test_supports_match_any("/access_key.all", :admin_auth, :key, :access_key)
    test_supports_match_all("/access_key.all", :admin_auth, :key, :access_key)
  end

  describe "/access_key.create" do
    test "responds with a key with the secret key" do
      response = admin_user_request("/access_key.create")
      key = get_last_inserted(Key)

      # Cannot do `assert response == %{...}` because we don't know the value of `secret_key`.
      # So we assert by pattern matching to validate the response structure, then directly
      # compare each data field for its values.
      assert %{
               "version" => "1",
               "success" => true,
               "data" => %{
                 "object" => "key",
                 "id" => _,
                 "access_key" => _,
                 "secret_key" => _,
                 "account_id" => _,
                 "enabled" => _,
                 "expired" => _,
                 "created_at" => _,
                 "updated_at" => _,
                 "deleted_at" => _
               }
             } = response

      assert response["data"]["id"] == key.id
      assert response["data"]["access_key"] == key.access_key
      assert response["data"]["account_id"] == Account.get_master_account().id
      assert response["data"]["expired"] == !key.enabled
      assert response["data"]["enabled"] == key.enabled
      assert response["data"]["created_at"] == DateFormatter.to_iso8601(key.inserted_at)
      assert response["data"]["updated_at"] == DateFormatter.to_iso8601(key.updated_at)
      assert response["data"]["deleted_at"] == DateFormatter.to_iso8601(key.deleted_at)

      # We cannot know the `secret_key` from the controller call,
      # so we can only check that it is a string with some length.
      assert String.length(response["data"]["secret_key"]) > 0
    end

    test "generates an activity log" do
      timestamp = DateTime.utc_now()
      response = admin_user_request("/access_key.create")

      assert response["success"] == true
      key = get_last_inserted(Key)
      account = Account.get_master_account()

      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: get_test_admin(),
        target: key,
        changes: %{
          "account_uuid" => account.uuid,
          "access_key" => key.access_key,
          "secret_key_hash" => key.secret_key_hash
        },
        encrypted_changes: %{}
      )
    end
  end

  describe "/access_key.update" do
    test "disables the key" do
      key = insert(:key)
      assert key.enabled == true

      response =
        admin_user_request("/access_key.update", %{
          id: key.id,
          expired: true
        })

      assert response["data"]["id"] == key.id
      assert response["data"]["expired"] == true
      assert response["data"]["enabled"] == false
    end

    test "enables the key" do
      key = insert(:key, enabled: false)
      assert key.enabled == false

      response =
        admin_user_request("/access_key.update", %{
          id: key.id,
          expired: false
        })

      assert response["data"]["id"] == key.id
      assert response["data"]["expired"] == false
      assert response["data"]["enabled"] == true
    end

    test "does not update any other fields" do
      key = insert(:key, access_key: "key", secret_key: "secret", secret_key_hash: "hash")
      assert key.enabled == true

      response =
        admin_user_request("/access_key.update", %{
          id: key.id,
          expired: true,
          access_key: "new_key",
          secret_key: "new_secret_key",
          secret_key_hash: "new_secret_key_hash"
        })

      assert response["data"]["id"] == key.id
      assert response["data"]["expired"] == true
      assert response["data"]["enabled"] == false
      assert response["data"]["access_key"] == "key"
      assert response["data"]["secret_key"] == nil

      # Because secret_key_hash is not returned, fetch to confirm it was not changed
      updated = Key.get(key.id)
      assert updated.secret_key_hash == key.secret_key_hash
    end

    test "generates an activity log" do
      key = insert(:key)
      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/access_key.update", %{
          id: key.id,
          expired: true
        })

      assert response["success"] == true

      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: get_test_admin(),
        target: key,
        changes: %{
          "enabled" => false
        },
        encrypted_changes: %{}
      )
    end
  end

  describe "/access_key.enable_or_disable" do
    test "disables the key" do
      key = insert(:key)
      assert key.enabled == true

      response =
        admin_user_request("/access_key.enable_or_disable", %{
          id: key.id,
          enabled: false
        })

      assert response["data"]["id"] == key.id
      assert response["data"]["enabled"] == false
    end

    test "disabling a key twice doesn't re-enable it" do
      key = insert(:key)
      assert key.enabled == true

      response =
        admin_user_request("/access_key.enable_or_disable", %{
          id: key.id,
          enabled: false
        })

      assert response["data"]["id"] == key.id
      assert response["data"]["enabled"] == false

      response =
        admin_user_request("/access_key.enable_or_disable", %{
          id: key.id,
          enabled: false
        })

      assert response["data"]["id"] == key.id
      assert response["data"]["enabled"] == false
    end

    test "enables the key" do
      key = insert(:key, enabled: false)
      assert key.enabled == false

      response =
        admin_user_request("/access_key.enable_or_disable", %{
          id: key.id,
          enabled: true
        })

      assert response["data"]["id"] == key.id
      assert response["data"]["enabled"] == true
    end

    test "generates an activity log" do
      key = insert(:key)
      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/access_key.enable_or_disable", %{
          id: key.id,
          enabled: false
        })

      assert response["success"] == true

      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: get_test_admin(),
        target: key,
        changes: %{
          "enabled" => false
        },
        encrypted_changes: %{}
      )
    end
  end

  describe "/access_key.delete" do
    test "responds with an empty success if provided a key id" do
      key = insert(:key)
      response = admin_user_request("/access_key.delete", %{id: key.id})

      assert response == %{"version" => "1", "success" => true, "data" => %{}}
    end

    test "responds with an empty success if provided an access_key" do
      key = insert(:key)
      response = admin_user_request("/access_key.delete", %{access_key: key.access_key})

      assert response == %{"version" => "1", "success" => true, "data" => %{}}
    end

    test "responds with an error if the provided id is not found" do
      response = admin_user_request("/access_key.delete", %{id: "wrong_id"})

      assert response == %{
               "version" => "1",
               "success" => false,
               "data" => %{
                 "code" => "key:not_found",
                 "description" => "The key could not be found.",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end

    test "responds with an error if the user is not authorized to delete the key" do
      key = insert(:key)
      auth_token = insert(:auth_token, owner_app: "admin_api")

      attrs = %{id: key.id}
      opts = [user_id: auth_token.user.id, auth_token: auth_token.token]
      response = admin_user_request("/access_key.delete", attrs, opts)

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
      key = insert(:key)

      timestamp = DateTime.utc_now()
      response = admin_user_request("/access_key.delete", %{id: key.id})

      assert response["success"] == true

      key = Repo.get_by(Key, %{id: key.id})
      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: get_test_admin(),
        target: key,
        changes: %{"deleted_at" => DateFormatter.to_iso8601(key.deleted_at)},
        encrypted_changes: %{}
      )
    end
  end
end
