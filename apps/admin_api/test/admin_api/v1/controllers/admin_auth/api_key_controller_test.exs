defmodule AdminAPI.V1.AdminAuth.APIKeyControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.Web.Date
  alias EWalletDB.Helpers.Preloader
  alias EWalletDB.{Account, APIKey, Repo}

  describe "/api_key.all" do
    test "responds with a list of api keys when no params are given" do
      [api_key1, api_key2] = APIKey |> ensure_num_records(2) |> Preloader.preload(:account)

      assert admin_user_request("/api_key.all") ==
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
                       "created_at" => Date.to_iso8601(api_key1.inserted_at),
                       "updated_at" => Date.to_iso8601(api_key1.updated_at),
                       "deleted_at" => Date.to_iso8601(api_key1.deleted_at)
                     },
                     %{
                       "object" => "api_key",
                       "id" => api_key2.id,
                       "key" => api_key2.key,
                       "account_id" => api_key2.account.id,
                       "owner_app" => api_key2.owner_app,
                       "expired" => false,
                       "created_at" => Date.to_iso8601(api_key2.inserted_at),
                       "updated_at" => Date.to_iso8601(api_key2.updated_at),
                       "deleted_at" => Date.to_iso8601(api_key2.deleted_at)
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

    test "responds with a list of api keys when given params" do
      [api_key, _] = ensure_num_records(APIKey, 2)
      api_key = Preloader.preload(api_key, :account)

      attrs = %{
        search_term: "",
        page: 1,
        per_page: 1,
        sort_by: "created_at",
        sort_dir: "asc"
      }

      assert admin_user_request("/api_key.all", attrs) ==
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
                       "created_at" => Date.to_iso8601(api_key.inserted_at),
                       "updated_at" => Date.to_iso8601(api_key.updated_at),
                       "deleted_at" => Date.to_iso8601(api_key.deleted_at)
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

    test_supports_match_any("/api_key.all", :admin_auth, :api_key, :key)
    test_supports_match_all("/api_key.all", :admin_auth, :api_key, :key)
  end

  describe "/api_key.create" do
    test "responds with an API key on success" do
      response = admin_user_request("/api_key.create", %{})
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
                 "created_at" => Date.to_iso8601(api_key.inserted_at),
                 "updated_at" => Date.to_iso8601(api_key.updated_at),
                 "deleted_at" => Date.to_iso8601(api_key.deleted_at)
               }
             }
    end
  end

  describe "/api_key.update" do
    test "disables the API key" do
      api_key = :api_key |> insert() |> Repo.preload(:account)
      assert api_key.expired == false

      response =
        admin_user_request("/api_key.update", %{
          id: api_key.id,
          expired: true
        })

      assert response["data"]["id"] == api_key.id
      assert response["data"]["expired"] == true
    end

    test "enables the API key" do
      api_key = :api_key |> insert(expired: true) |> Repo.preload(:account)
      assert api_key.expired == true

      response =
        admin_user_request("/api_key.update", %{
          id: api_key.id,
          expired: false
        })

      assert response["data"]["id"] == api_key.id
      assert response["data"]["expired"] == false
    end

    test "does not update any other fields" do
      api_key = :api_key |> insert() |> Repo.preload(:account)
      assert api_key.expired == false

      response =
        admin_user_request("/api_key.update", %{
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
                 "account_id" => api_key.account.id,
                 "owner_app" => api_key.owner_app,
                 "created_at" => Date.to_iso8601(api_key.inserted_at),
                 "updated_at" => Date.to_iso8601(updated.updated_at),
                 "deleted_at" => Date.to_iso8601(api_key.deleted_at)
               }
             }
    end
  end

  describe "/api_key.delete" do
    test "responds with an empty success if provided a valid id" do
      api_key = insert(:api_key)
      response = admin_user_request("/api_key.delete", %{id: api_key.id})

      assert response == %{
               "version" => "1",
               "success" => true,
               "data" => %{}
             }
    end

    test "responds with an error if the provided id is not found" do
      response = admin_user_request("/api_key.delete", %{id: "wrong_id"})

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
      auth_token = insert(:auth_token, owner_app: "admin_api")

      attrs = %{id: api_key.id}
      opts = [user_id: auth_token.user.id, auth_token: auth_token.token]
      response = admin_user_request("/api_key.delete", attrs, opts)

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
  end
end
