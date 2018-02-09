defmodule AdminAPI.V1.KeyControllerTest do
  use AdminAPI.ConnCase, async: true
  import Ecto.Query
  alias EWallet.Web.Date
  alias EWalletDB.{Key, Repo}

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

  describe "/access_key.create" do
    test "responds with a key with the secret key" do
      master_account = insert(:account, %{master: true})
      _account       = insert(:account, %{master: false})
      response       = user_request("/access_key.create")
      key            = Key |> last(:inserted_at) |> Repo.one

      # Cannot do `assert response == %{...}` because we don't know the value of `secret_key`.
      # So we assert by pattern matching to validate the response structure, then directly
      # compare each data field for its values.
      assert %{
        "version" => "1",
        "success" => true,
        "data" => %{
          "object"     => "key",
          "id"         => _,
          "access_key" => _,
          "secret_key" => _,
          "account_id" => _,
          "created_at" => _,
          "updated_at" => _
        }
      } = response

      assert response["data"]["id"] == key.id
      assert response["data"]["access_key"] == key.access_key
      assert response["data"]["account_id"] == master_account.id
      assert response["data"]["created_at"] == Date.to_iso8601(key.inserted_at)
      assert response["data"]["updated_at"] == Date.to_iso8601(key.updated_at)

      # We cannot know the `secret_key` from the controller call,
      # so we can only check that it is a string with some length.
      assert String.length(response["data"]["secret_key"]) > 0
    end
  end
end
