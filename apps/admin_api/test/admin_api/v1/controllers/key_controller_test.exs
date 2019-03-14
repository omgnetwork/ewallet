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

defmodule AdminAPI.V1.KeyControllerTest do
  use AdminAPI.ConnCase, async: true
  alias Utils.Helpers.DateFormatter
  alias EWalletDB.{Key, Repo}

  describe "/access_key.all" do
    test_with_auths "responds with a list of keys without secret keys" do
      key_1 = Key.get_by(%{access_key: @access_key})
      key_2 = insert(:key, %{secret_key: "the_secret_key"})

      response = request("/access_key.all")

      assert response["success"]
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

    test_with_auths "responds with a list of keys excluding the soft-deleted ones" do
      originator = insert(:user)
      [key1, key2, key3] = ensure_num_records(Key, 3)
      {:ok, _} = Key.delete(key2, originator)

      response = request("/access_key.all")

      assert response["success"]
      keys = response["data"]["data"]
      assert Enum.count(keys) == 2
      assert Enum.any?(keys, fn a -> a["id"] == key1.id end)
      refute Enum.any?(keys, fn a -> a["id"] == key2.id end)
      assert Enum.any?(keys, fn a -> a["id"] == key3.id end)
    end

    test_supports_match_any("/access_key.all", :key, :access_key)
    test_supports_match_all("/access_key.all", :key, :access_key)
  end

  describe "/access_key.create" do
    test_with_auths "responds with a key with the secret key" do
      response = request("/access_key.create")
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
                 "name" => _,
                 "access_key" => _,
                 "secret_key" => _,
                 "account_id" => nil,
                 "enabled" => _,
                 "expired" => _,
                 "created_at" => _,
                 "updated_at" => _,
                 "deleted_at" => _
               }
             } = response

      assert response["data"]["id"] == key.id
      assert response["data"]["access_key"] == key.access_key
      assert response["data"]["account_id"] == nil
      assert response["data"]["expired"] == !key.enabled
      assert response["data"]["enabled"] == key.enabled
      assert response["data"]["created_at"] == DateFormatter.to_iso8601(key.inserted_at)
      assert response["data"]["updated_at"] == DateFormatter.to_iso8601(key.updated_at)
      assert response["data"]["deleted_at"] == DateFormatter.to_iso8601(key.deleted_at)

      # We cannot know the `secret_key` from the controller call,
      # so we can only check that it is a string with some length.
      assert String.length(response["data"]["secret_key"]) > 0
    end

    defp assert_create_logs(logs, originator, target) do
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: originator,
        target: target,
        changes: %{
          "access_key" => target.access_key,
          "secret_key_hash" => target.secret_key_hash
        },
        encrypted_changes: %{}
      )
    end

    test_with_auths "generates an activity log for an admin request" do
      timestamp = DateTime.utc_now()
      response = admin_user_request("/access_key.create")

      assert response["success"] == true
      key = get_last_inserted(Key)

      timestamp
      |> get_all_activity_logs_since()
      |> assert_create_logs(get_test_admin(), key)
    end

    test_with_auths "generates an activity log for a provider request" do
      timestamp = DateTime.utc_now()
      response = provider_request("/access_key.create")

      assert response["success"] == true
      key = get_last_inserted(Key)

      timestamp
      |> get_all_activity_logs_since()
      |> assert_create_logs(get_test_key(), key)
    end
  end

  describe "/access_key.update" do
    test_with_auths "disables the key" do
      key = insert(:key)
      assert key.enabled == true

      response =
        request("/access_key.update", %{
          id: key.id,
          expired: true
        })

      assert response["success"]
      assert response["data"]["id"] == key.id
      assert response["data"]["expired"] == true
      assert response["data"]["enabled"] == false
    end

    test_with_auths "enables the key" do
      key = insert(:key, enabled: false)
      assert key.enabled == false

      response =
        request("/access_key.update", %{
          id: key.id,
          expired: false
        })

      assert response["success"]
      assert response["data"]["id"] == key.id
      assert response["data"]["expired"] == false
      assert response["data"]["enabled"] == true
    end

    test_with_auths "does not update any other fields" do
      key = insert(:key, access_key: "key", secret_key: "secret", secret_key_hash: "hash")
      assert key.enabled == true

      response =
        request("/access_key.update", %{
          id: key.id,
          expired: true,
          access_key: "new_key",
          secret_key: "new_secret_key",
          secret_key_hash: "new_secret_key_hash"
        })

      assert response["success"]
      assert response["data"]["id"] == key.id
      assert response["data"]["expired"] == true
      assert response["data"]["enabled"] == false
      assert response["data"]["access_key"] == "key"
      assert response["data"]["secret_key"] == nil

      # Because secret_key_hash is not returned, fetch to confirm it was not changed
      updated = Key.get(key.id)
      assert updated.secret_key_hash == key.secret_key_hash
    end

    defp assert_update_logs(logs, originator, target) do
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: originator,
        target: target,
        changes: %{
          "enabled" => false
        },
        encrypted_changes: %{}
      )
    end

    test "generates an activity log for an admin request" do
      key = insert(:key)
      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/access_key.enable_or_disable", %{
          id: key.id,
          enabled: false
        })

      assert response["success"] == true

      timestamp
      |> get_all_activity_logs_since()
      |> assert_update_logs(get_test_admin(), key)
    end

    test "generates an activity log for a provider request" do
      key = insert(:key)
      timestamp = DateTime.utc_now()

      response =
        provider_request("/access_key.enable_or_disable", %{
          id: key.id,
          enabled: false
        })

      assert response["success"] == true

      timestamp
      |> get_all_activity_logs_since()
      |> assert_update_logs(get_test_key(), key)
    end
  end

  describe "/access_key.enable_or_disable" do
    test_with_auths "disables the key" do
      key = insert(:key)
      assert key.enabled == true

      response =
        request("/access_key.enable_or_disable", %{
          id: key.id,
          enabled: false
        })

      assert response["success"]
      assert response["data"]["id"] == key.id
      assert response["data"]["enabled"] == false
    end

    test_with_auths "disabling a key twice doesn't re-enable it" do
      key = insert(:key)
      assert key.enabled == true

      response =
        request("/access_key.enable_or_disable", %{
          id: key.id,
          enabled: false
        })

      assert response["success"]
      assert response["data"]["id"] == key.id
      assert response["data"]["enabled"] == false

      response =
        request("/access_key.enable_or_disable", %{
          id: key.id,
          enabled: false
        })

      assert response["success"]
      assert response["data"]["id"] == key.id
      assert response["data"]["enabled"] == false
    end

    test_with_auths "enables the key" do
      key = insert(:key, enabled: false)
      assert key.enabled == false

      response =
        request("/access_key.enable_or_disable", %{
          id: key.id,
          enabled: true
        })

      assert response["success"]
      assert response["data"]["id"] == key.id
      assert response["data"]["enabled"] == true
    end

    defp assert_enable_logs(logs, originator, target) do
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: originator,
        target: target,
        changes: %{
          "enabled" => false
        },
        encrypted_changes: %{}
      )
    end

    test "generates an activity log for an admin request" do
      key = insert(:key)
      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/access_key.enable_or_disable", %{
          id: key.id,
          enabled: false
        })

      assert response["success"] == true

      timestamp
      |> get_all_activity_logs_since()
      |> assert_enable_logs(get_test_admin(), key)
    end

    test "generates an activity log for a provider request" do
      key = insert(:key)
      timestamp = DateTime.utc_now()

      response =
        provider_request("/access_key.enable_or_disable", %{
          id: key.id,
          enabled: false
        })

      assert response["success"] == true

      timestamp
      |> get_all_activity_logs_since()
      |> assert_enable_logs(get_test_key(), key)
    end
  end

  describe "/access_key.delete" do
    test_with_auths "responds with an empty success if provided a key id" do
      key = insert(:key)
      response = request("/access_key.delete", %{id: key.id})

      assert response == %{"version" => "1", "success" => true, "data" => %{}}
    end

    test_with_auths "responds with an empty success if provided an access_key" do
      key = insert(:key)
      response = request("/access_key.delete", %{access_key: key.access_key})

      assert response == %{"version" => "1", "success" => true, "data" => %{}}
    end

    test_with_auths "responds with an error if the provided id is not found" do
      response = request("/access_key.delete", %{id: "wrong_id"})

      assert response["success"] == false
      assert response["data"]["code"] == "unauthorized"
    end

    test_with_auths "responds with an error if the user is not authorized to delete the key" do
      key_to_delete = insert(:key)
      key = insert(:key)
      auth_token = insert(:auth_token, owner_app: "admin_api")

      attrs = %{id: key_to_delete.id}

      opts = [
        user_id: auth_token.user.id,
        auth_token: auth_token.token,
        access_key: key.access_key,
        secret_key: key.secret_key
      ]

      response = request("/access_key.delete", attrs, opts)

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

    defp assert_delete_logs(logs, originator, target) do
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: originator,
        target: target,
        changes: %{"deleted_at" => DateFormatter.to_iso8601(target.deleted_at)},
        encrypted_changes: %{}
      )
    end

    test "generates an activity log for an admin request" do
      key = insert(:key)

      timestamp = DateTime.utc_now()
      response = admin_user_request("/access_key.delete", %{id: key.id})

      assert response["success"] == true

      key = Repo.get_by(Key, %{id: key.id})

      timestamp
      |> get_all_activity_logs_since()
      |> assert_delete_logs(get_test_admin(), key)
    end

    test "generates an activity log for a provider request" do
      key = insert(:key)

      timestamp = DateTime.utc_now()
      response = provider_request("/access_key.delete", %{id: key.id})

      assert response["success"] == true

      key = Repo.get_by(Key, %{id: key.id})

      timestamp
      |> get_all_activity_logs_since()
      |> assert_delete_logs(get_test_key(), key)
    end
  end
end
