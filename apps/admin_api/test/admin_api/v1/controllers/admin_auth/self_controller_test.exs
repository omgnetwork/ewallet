defmodule AdminAPI.V1.AdminAuth.SelfControllerTest do
  use AdminAPI.ConnCase, async: true
  import Ecto.Query
  alias EWallet.Web.Date
  alias EWalletDB.{Account, Membership, Repo, User}
  alias EWalletDB.Helpers.Assoc

  describe "/me.get" do
    test "responds with user data" do
      response = admin_user_request("/me.get")

      assert response["success"]
      assert response["data"]["email"] == "email@example.com"
    end
  end

  describe "/me.update" do
    test "update the current user with the given parameters" do
      response =
        admin_user_request("/me.update", %{
          email: "test_1337@example.com",
          metadata: %{"key" => "value_1337"},
          encrypted_metadata: %{"key" => "value_1337"}
        })

      assert response["success"] == true
      assert response["data"]["object"] == "user"
      assert response["data"]["email"] == "test_1337@example.com"
      assert response["data"]["metadata"] == %{"key" => "value_1337"}
      assert response["data"]["encrypted_metadata"] == %{"key" => "value_1337"}
    end

    test "doesn't update params that are not provided" do
      user = get_test_admin()
      response = admin_user_request("/me.update", %{})

      assert response["success"] == true
      assert response["data"]["object"] == "user"
      assert response["data"]["email"] == user.email
      assert response["data"]["metadata"] == user.metadata
      assert response["data"]["encrypted_metadata"] == user.encrypted_metadata
    end

    test "ignore additional/invalid params" do
      user = get_test_admin()
      response = admin_user_request("/me.update", %{provider_user_id: "test_puid_1337"})

      assert response["success"] == true
      assert response["data"]["object"] == "user"
      assert response["data"]["provider_user_id"] == user.provider_user_id
    end

    test "raise an error if the update is not valid" do
      insert(:user, %{email: "user1@example.com"})
      response = admin_user_request("/me.update", %{email: "user1@example.com"})

      assert response["success"] == false

      assert response["data"]["description"] ==
               "Invalid parameter provided `email` has already been taken."

      assert response["data"]["code"] == "client:invalid_parameter"
    end
  end

  describe "/me.upload_avatar" do
    test "uploads an avatar for the specified user" do
      account = insert(:account)
      role = insert(:role, %{name: "some_role"})
      admin = get_test_admin()
      uuid = admin.id
      _membership = insert(:membership, %{user: admin, account: account, role: role})

      response =
        admin_user_request("/me.upload_avatar", %{
          "avatar" => %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        })

      assert response["success"]
      assert response["data"]["object"] == "user"
      assert response["data"]["email"] == admin.email

      assert response["data"]["avatar"]["large"] =~
               "http://localhost:4000/public/uploads/test/user/avatars/#{uuid}/large.png?v="

      assert response["data"]["avatar"]["original"] =~
               "http://localhost:4000/public/uploads/test/user/avatars/#{uuid}/original.jpg?v="

      assert response["data"]["avatar"]["small"] =~
               "http://localhost:4000/public/uploads/test/user/avatars/#{uuid}/small.png?v="

      assert response["data"]["avatar"]["thumb"] =~
               "http://localhost:4000/public/uploads/test/user/avatars/#{uuid}/thumb.png?v="
    end

    test "returns an error when 'avatar' is not sent" do
      response = admin_user_request("/me.upload_avatar", %{})

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test "removes the avatar from a user" do
      account = insert(:account)
      role = insert(:role, %{name: "some_role"})
      admin = get_test_admin()
      uuid = admin.id
      _membership = insert(:membership, %{user: admin, account: account, role: role})

      response =
        admin_user_request("/me.upload_avatar", %{
          "id" => uuid,
          "avatar" => %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        })

      assert response["success"]

      response =
        admin_user_request("/me.upload_avatar", %{
          "avatar" => nil
        })

      assert response["success"]

      admin = User.get(admin.id)
      assert admin.avatar == nil
    end

    test "removes the avatar from a user with empty string" do
      account = insert(:account)
      role = insert(:role, %{name: "some_role"})
      admin = get_test_admin()
      _membership = insert(:membership, %{user: admin, account: account, role: role})

      response =
        admin_user_request("/me.upload_avatar", %{
          "avatar" => %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        })

      assert response["success"]

      response =
        admin_user_request("/me.upload_avatar", %{
          "avatar" => ""
        })

      assert response["success"]

      admin = User.get(admin.id)
      assert admin.avatar == nil
    end

    test "removes the avatar from a user with 'null' string" do
      account = insert(:account)
      role = insert(:role, %{name: "some_role"})
      admin = get_test_admin()
      _membership = insert(:membership, %{user: admin, account: account, role: role})

      response =
        admin_user_request("/me.upload_avatar", %{
          "avatar" => %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        })

      assert response["success"]

      response =
        admin_user_request("/me.upload_avatar", %{
          "avatar" => "null"
        })

      assert response["success"]

      admin = User.get(admin.id)
      assert admin.avatar == nil
    end
  end

  describe "/me.get_account" do
    test "responds with an account" do
      account = User.get_account(get_test_admin())

      assert admin_user_request("/me.get_account") ==
               %{
                 "version" => "1",
                 "success" => true,
                 "data" => %{
                   "object" => "account",
                   "id" => account.id,
                   "socket_topic" => "account:#{account.id}",
                   "parent_id" => Assoc.get(account, [:parent, :id]),
                   "name" => account.name,
                   "description" => account.description,
                   "master" => Account.master?(account),
                   "category_ids" => [],
                   "categories" => %{
                     "object" => "list",
                     "data" => []
                   },
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
      user = get_test_admin()
      Repo.delete_all(from(m in Membership, where: m.user_uuid == ^user.uuid))

      assert admin_user_request("/me.get_account") ==
               %{
                 "version" => "1",
                 "success" => false,
                 "data" => %{
                   "object" => "error",
                   "code" => "user:account_not_found",
                   "description" => "There is no account assigned to the provided user",
                   "messages" => nil
                 }
               }
    end
  end

  describe "/me.get_accounts" do
    test "responds with a list of accounts" do
      user = get_test_admin()
      parent = insert(:account)
      account = insert(:account, %{parent: parent})

      # Clear all memberships for this user then add just one for precision
      Repo.delete_all(from(m in Membership, where: m.user_uuid == ^user.uuid))
      Membership.assign(user, account, "admin")

      assert admin_user_request("/me.get_accounts") ==
               %{
                 "version" => "1",
                 "success" => true,
                 "data" => %{
                   "object" => "list",
                   "data" => [
                     %{
                       "object" => "account",
                       "id" => account.id,
                       "socket_topic" => "account:#{account.id}",
                       "parent_id" => Assoc.get(account, [:parent, :id]),
                       "name" => account.name,
                       "description" => account.description,
                       "master" => Account.master?(account),
                       "category_ids" => [],
                       "categories" => %{
                         "object" => "list",
                         "data" => []
                       },
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
