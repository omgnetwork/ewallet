defmodule AdminAPI.V1.APIKeyControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.Web.Date
  alias EWalletDB.{Account, APIKey}

  describe "/api_key.all" do
    test "responds with a list of api keys when no params are given" do
      [api_key1, api_key2] = ensure_num_records(APIKey, 2)

      assert user_request("/api_key.all") ==
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
                "account_id" => api_key1.account_id,
                "owner_app" => api_key1.owner_app,
                "created_at" => Date.to_iso8601(api_key1.inserted_at),
                "updated_at" => Date.to_iso8601(api_key1.updated_at),
                "deleted_at" => Date.to_iso8601(api_key1.deleted_at)
              },
              %{
                "object" => "api_key",
                "id" => api_key2.id,
                "key" => api_key2.key,
                "account_id" => api_key2.account_id,
                "owner_app" => api_key2.owner_app,
                "created_at" => Date.to_iso8601(api_key2.inserted_at),
                "updated_at" => Date.to_iso8601(api_key2.updated_at),
                "deleted_at" => Date.to_iso8601(api_key2.deleted_at)
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

    test "responds with a list of api keys when given params" do
      [api_key, _] = ensure_num_records(APIKey, 2)
      attrs = %{
        search_term: "",
        page: 1,
        per_page: 1,
        sort_by: "created_at",
        sort_dir: "asc"
      }

      assert user_request("/api_key.all", attrs) ==
        %{
          "version" => "1",
          "success" => true,
          "data" => %{
            "object" => "list",
            "data" => [
              %{
                "object"     => "api_key",
                "id"         => api_key.id,
                "key"        => api_key.key,
                "account_id" => api_key.account_id,
                "owner_app"  => api_key.owner_app,
                "created_at" => Date.to_iso8601(api_key.inserted_at),
                "updated_at" => Date.to_iso8601(api_key.updated_at),
                "deleted_at" => Date.to_iso8601(api_key.deleted_at)
              }
            ],
            "pagination" => %{
              "current_page"  => 1,
              "per_page"      => 1,
              "is_first_page" => true,
              "is_last_page"  => false
            }
          }
        }
    end
  end

  describe "/api_key.create" do
    test "responds with an API key on success" do
      response       = user_request("/api_key.create", %{owner_app: "some_app"})
      api_key        = get_last_inserted(APIKey)

      assert response == %{
        "version" => "1",
        "success" => true,
        "data" => %{
          "object"     => "api_key",
          "id"         => api_key.id,
          "key"        => api_key.key,
          "account_id" => Account.get_master_account().id,
          "owner_app"  => "some_app",
          "created_at" => Date.to_iso8601(api_key.inserted_at),
          "updated_at" => Date.to_iso8601(api_key.updated_at),
          "deleted_at" => Date.to_iso8601(api_key.deleted_at)
        }
      }
    end

    test "returns error if owner_app is not provided" do
      response = user_request("/api_key.create", %{owner_app: nil})

      assert response == %{
        "version" => "1",
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "client:invalid_parameter",
          "description" => "Invalid parameter provided `owner_app` can't be blank.",
          "messages" => %{
            "owner_app" => ["required"]
          }
        }
      }
    end
  end

  describe "/api_key.delete" do
    test "responds with an empty success if provided a valid id" do
      api_key  = insert(:api_key)
      response = user_request("/api_key.delete", %{id: api_key.id})

      assert response == %{
        "version" => "1",
        "success" => true,
        "data" => %{}
      }
    end

    test "responds with an error if the provided id is not found" do
      response = user_request("/api_key.delete", %{id: "wrong_id"})

      assert response == %{
        "version" => "1",
        "success" => false,
        "data" => %{
          "code" => "api_key:not_found",
          "description" => "The API key could not be found",
          "messages" => nil,
          "object" => "error"
        }
      }
    end

    test "responds with an error if the given id is used for making the deletion request" do
      response = user_request("/api_key.delete", %{id: @api_key_id})

      assert response == %{
        "version" => "1",
        "success" => false,
        "data" => %{
          "code" => "client:invalid_parameter",
          "description" => "The given API key is being used for this request",
          "messages" => nil,
          "object" => "error"
        }
      }
    end
  end
end
