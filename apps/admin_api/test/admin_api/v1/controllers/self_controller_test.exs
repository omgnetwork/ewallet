defmodule AdminAPI.V1.SelfControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.Web.Date

  describe "/me.get" do
    test "responds with user data" do
      response = user_request("/me.get")

      assert response["success"]
      assert response["data"]["username"] == @username
    end
  end

  describe "/me.get_account" do
    test "responds with an account" do
      account     = insert(:account)
      _membership = insert(:membership, %{user: get_test_user(), account: account})

      assert user_request("/me.get_account") ==
        %{
          "version" => "1",
          "success" => true,
          "data" => %{
            "object" => "account",
            "id" => account.id,
            "parent_id" => account.parent_id,
            "name" => account.name,
            "description" => account.description,
            "master" => account.master,
            "avatar" => %{
              "original" => nil,
              "large" => nil,
              "small" => nil,
              "thumb" => nil
            },
            "created_at" => Date.to_iso8601(account.inserted_at),
            "updated_at" => Date.to_iso8601(account.updated_at)
          }
        }
    end

    test "responds with error if the user does not have an account" do
      assert user_request("/me.get_account") ==
        %{
          "version" => "1",
          "success" => false,
          "data"    => %{
            "object"      => "error",
            "code"        => "user:account_not_found",
            "description" => "There is no account assigned to the provided user",
            "messages"    => nil
          }
        }
    end
  end

  describe "/me.get_accounts" do
    test "responds with a list of accounts" do
      account     = insert(:account)
      _membership = insert(:membership, %{user: get_test_user(), account: account})

      assert user_request("/me.get_accounts") ==
        %{
          "version" => "1",
          "success" => true,
          "data" => %{
            "object" => "list",
            "data" => [%{
              "object" => "account",
              "id" => account.id,
              "parent_id" => account.parent_id,
              "name" => account.name,
              "description" => account.description,
              "master" => account.master,
              "avatar" => %{
                "original" => nil,
                "large" => nil,
                "small" => nil,
                "thumb" => nil
              },
              "created_at" => Date.to_iso8601(account.inserted_at),
              "updated_at" => Date.to_iso8601(account.updated_at)
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
