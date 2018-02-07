defmodule AdminAPI.V1.KeyControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.Web.Date

  describe "/access_key.all" do
    test "responds with a list of keys without secret keys" do
      key = insert(:key, %{secret_key: "the_secret_key"})

      assert user_request("/access_key.all") ==
        %{
          "version" => "1",
          "success" => true,
          "data" => %{
            "object" => "list",
            "data" => [%{
              "object" => "key",
              "id" => key.id,
              "access_key" => key.access_key,
              "secret_key" => nil, # Secret keys cannot be retrieved after creation
              "account_id" => key.account_id,
              "created_at" => Date.to_iso8601(key.inserted_at),
              "updated_at" => Date.to_iso8601(key.updated_at)
            }],
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
