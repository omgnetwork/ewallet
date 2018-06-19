defmodule AdminAPI.V1.KeyControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.Web.Date
  alias EWalletDB.{Repo, Account, Key}
  alias EWalletDB.Helpers.Assoc

  describe "/access_key.all" do
    test "responds with a list of keys without secret keys" do
      key_1 = Key |> Repo.get_by(access_key: @access_key) |> Repo.preload([:account])
      key_2 = insert(:key, %{secret_key: "the_secret_key"})

      assert admin_user_request("/access_key.all") ==
               %{
                 "version" => "1",
                 "success" => true,
                 "data" => %{
                   "object" => "list",
                   "data" => [
                     %{
                       "object" => "key",
                       "id" => key_1.id,
                       "access_key" => key_1.access_key,
                       # Secret keys cannot be retrieved after creation
                       "secret_key" => nil,
                       "account_id" => Assoc.get(key_1, [:account, :id]),
                       "created_at" => Date.to_iso8601(key_1.inserted_at),
                       "updated_at" => Date.to_iso8601(key_1.updated_at),
                       "deleted_at" => Date.to_iso8601(key_1.deleted_at)
                     },
                     %{
                       "object" => "key",
                       "id" => key_2.id,
                       "access_key" => key_2.access_key,
                       # Secret keys cannot be retrieved after creation
                       "secret_key" => nil,
                       "account_id" => Assoc.get(key_2, [:account, :id]),
                       "created_at" => Date.to_iso8601(key_2.inserted_at),
                       "updated_at" => Date.to_iso8601(key_2.updated_at),
                       "deleted_at" => Date.to_iso8601(key_2.deleted_at)
                     }
                   ],
                   "pagination" => %{
                     "current_page" => 1,
                     "per_page" => 10,
                     "is_first_page" => true,
                     "is_last_page" => true
                   }
                 }
               }
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
                 "created_at" => _,
                 "updated_at" => _,
                 "deleted_at" => _
               }
             } = response

      assert response["data"]["id"] == key.id
      assert response["data"]["access_key"] == key.access_key
      assert response["data"]["account_id"] == Account.get_master_account().id
      assert response["data"]["created_at"] == Date.to_iso8601(key.inserted_at)
      assert response["data"]["updated_at"] == Date.to_iso8601(key.updated_at)
      assert response["data"]["deleted_at"] == Date.to_iso8601(key.deleted_at)

      # We cannot know the `secret_key` from the controller call,
      # so we can only check that it is a string with some length.
      assert String.length(response["data"]["secret_key"]) > 0
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
                 "description" => "The key could not be found",
                 "messages" => nil,
                 "object" => "error"
               }
             }
    end
  end
end
