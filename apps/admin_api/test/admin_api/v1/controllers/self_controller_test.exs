defmodule AdminAPI.V1.SelfControllerTest do
  use AdminAPI.ConnCase, async: true
  import Ecto.Query
  alias EWallet.Web.Date
  alias EWalletDB.{Account, Membership, Repo, User}

  describe "/me.get" do
    test "responds with user data" do
      response = user_request("/me.get")

      assert response["success"]
      assert response["data"]["username"] == @username
    end
  end

  describe "/me.get_account" do
    test "responds with an account" do
      account = User.get_account(get_test_user())

      assert user_request("/me.get_account") ==
        %{
          "version" => "1",
          "success" => true,
          "data" => %{
            "object" => "account",
            "id" => account.external_id,
            "socket_topic" => "account:#{account.id}",
            "parent_id" => account.parent_id,
            "name" => account.name,
            "description" => account.description,
            "master" => Account.master?(account),
            "metadata" => %{},
            "encrypted_metadata" => %{},
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
      user = get_test_user()
      Repo.delete_all(from m in Membership, where: m.user_id == ^user.id)

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
      user = get_test_user()
      parent = insert(:account)
      account = insert(:account, %{parent: parent})

      # Clear all memberships for this user then add just one for precision
      Repo.delete_all(from m in Membership, where: m.user_id == ^user.id)
      Membership.assign(user, account, "admin")

      assert user_request("/me.get_accounts") ==
        %{
          "version" => "1",
          "success" => true,
          "data" => %{
            "object" => "list",
            "data" => [
              %{
                "object" => "account",
                "id" => account.external_id,
                "socket_topic" => "account:#{account.id}",
                "parent_id" => account.parent.external_id,
                "name" => account.name,
                "description" => account.description,
                "master" => Account.master?(account),
                "metadata" => %{},
                "encrypted_metadata" => %{},
                "avatar" => %{
                  "original" => nil,
                  "large" => nil,
                  "small" => nil,
                  "thumb" => nil
                },
                "created_at" => Date.to_iso8601(account.inserted_at),
                "updated_at" => Date.to_iso8601(account.updated_at)
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
