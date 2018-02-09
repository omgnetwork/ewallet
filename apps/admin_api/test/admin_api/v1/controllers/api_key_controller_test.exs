defmodule AdminAPI.V1.APIKeyControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.Web.Date
  alias EWalletDB.APIKey

  describe "/api_key.all" do
    test "responds with a list of api keys" do
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
  end
end
