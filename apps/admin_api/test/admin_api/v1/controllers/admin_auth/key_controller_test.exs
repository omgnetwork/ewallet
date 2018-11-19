defmodule AdminAPI.V1.AdminAuth.KeyControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.Web.Date
  alias EWalletDB.{Account, Key, Repo}

  describe "/access_key.all" do
    test "responds with a list of keys without secret keys" do
      key_1 = Key |> Repo.get_by(access_key: @access_key) |> Repo.preload([:account])
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
      assert response["data"]["created_at"] == Date.to_iso8601(key.inserted_at)
      assert response["data"]["updated_at"] == Date.to_iso8601(key.updated_at)
      assert response["data"]["deleted_at"] == Date.to_iso8601(key.deleted_at)

      # We cannot know the `secret_key` from the controller call,
      # so we can only check that it is a string with some length.
      assert String.length(response["data"]["secret_key"]) > 0
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
  end
end
