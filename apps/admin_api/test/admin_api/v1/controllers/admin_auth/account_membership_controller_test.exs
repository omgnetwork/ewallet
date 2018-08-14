defmodule AdminAPI.V1.AdminAuth.AccountMembershipControllerTest do
  use AdminAPI.ConnCase, async: true
  alias Ecto.UUID
  alias EWallet.Web.Date
  alias EWalletDB.{User, Account}

  @redirect_url "http://localhost:4000/invite?email={email}&token={token}"

  describe "/account.get_members" do
    test "returns a list of users with role and status" do
      master = Account.get_master_account()
      admin = get_test_admin()
      account = insert(:account)
      user = insert(:user)
      role = insert(:role)
      _ = insert(:membership, %{account: account, user: user, role: role})

      response = admin_user_request("/account.get_members", %{id: account.id})

      assert response["success"] == true
      # created user + admin user = 2
      assert length(response["data"]["data"]) == 2

      assert Enum.member?(response["data"]["data"], %{
               "object" => "user",
               "id" => user.id,
               "socket_topic" => "user:#{user.id}",
               "username" => user.username,
               "provider_user_id" => user.provider_user_id,
               "email" => user.email,
               "metadata" => user.metadata,
               "encrypted_metadata" => %{},
               "created_at" => Date.to_iso8601(user.inserted_at),
               "updated_at" => Date.to_iso8601(user.updated_at),
               "account_role" => role.name,
               "status" => to_string(User.get_status(user)),
               "avatar" => %{
                 "original" => nil,
                 "large" => nil,
                 "small" => nil,
                 "thumb" => nil
               },
               "account" => %{
                 "avatar" => %{"large" => nil, "original" => nil, "small" => nil, "thumb" => nil},
                 "categories" => %{"data" => [], "object" => "list"},
                 "category_ids" => [],
                 "description" => account.description,
                 "encrypted_metadata" => %{},
                 "id" => account.id,
                 "master" => false,
                 "metadata" => %{},
                 "name" => account.name,
                 "object" => "account",
                 "parent_id" => account.parent.id,
                 "socket_topic" => "account:#{account.id}",
                 "created_at" => Date.to_iso8601(account.inserted_at),
                 "updated_at" => Date.to_iso8601(account.updated_at)
               }
             })

      assert Enum.member?(response["data"]["data"], %{
               "object" => "user",
               "id" => admin.id,
               "socket_topic" => "user:#{admin.id}",
               "username" => admin.username,
               "provider_user_id" => admin.provider_user_id,
               "email" => admin.email,
               "metadata" => admin.metadata,
               "encrypted_metadata" => %{},
               "created_at" => Date.to_iso8601(admin.inserted_at),
               "updated_at" => Date.to_iso8601(admin.updated_at),
               "account_role" => "admin",
               "status" => to_string(User.get_status(admin)),
               "avatar" => %{
                 "original" => nil,
                 "large" => nil,
                 "small" => nil,
                 "thumb" => nil
               },
               "account" => %{
                 "avatar" => %{"large" => nil, "original" => nil, "small" => nil, "thumb" => nil},
                 "categories" => %{"data" => [], "object" => "list"},
                 "category_ids" => [],
                 "description" => master.description,
                 "encrypted_metadata" => %{},
                 "id" => master.id,
                 "master" => true,
                 "metadata" => %{},
                 "name" => master.name,
                 "object" => "account",
                 "parent_id" => nil,
                 "socket_topic" => "account:#{master.id}",
                 "created_at" => Date.to_iso8601(master.inserted_at),
                 "updated_at" => Date.to_iso8601(master.updated_at)
               }
             })
    end

    test "returns the upper admins only if the account has no members" do
      admin = get_test_admin()
      master = Account.get_master_account()
      account = insert(:account)

      assert admin_user_request("/account.get_members", %{id: account.id}) ==
               %{
                 "version" => "1",
                 "success" => true,
                 "data" => %{
                   "object" => "list",
                   "data" => [
                     %{
                       "object" => "user",
                       "id" => admin.id,
                       "socket_topic" => "user:#{admin.id}",
                       "username" => admin.username,
                       "provider_user_id" => admin.provider_user_id,
                       "email" => admin.email,
                       "metadata" => admin.metadata,
                       "encrypted_metadata" => %{},
                       "created_at" => Date.to_iso8601(admin.inserted_at),
                       "updated_at" => Date.to_iso8601(admin.updated_at),
                       "account_role" => "admin",
                       "status" => to_string(User.get_status(admin)),
                       "avatar" => %{
                         "original" => nil,
                         "large" => nil,
                         "small" => nil,
                         "thumb" => nil
                       },
                       "account" => %{
                         "avatar" => %{
                           "large" => nil,
                           "original" => nil,
                           "small" => nil,
                           "thumb" => nil
                         },
                         "categories" => %{"data" => [], "object" => "list"},
                         "category_ids" => [],
                         "description" => master.description,
                         "encrypted_metadata" => %{},
                         "id" => master.id,
                         "master" => true,
                         "metadata" => %{},
                         "name" => master.name,
                         "object" => "account",
                         "parent_id" => nil,
                         "socket_topic" => "account:#{master.id}",
                         "created_at" => Date.to_iso8601(master.inserted_at),
                         "updated_at" => Date.to_iso8601(master.updated_at)
                       }
                     }
                   ]
                 }
               }
    end

    test "returns unauthorized error if account id could not be found" do
      assert admin_user_request("/account.get_members", %{
               id: "acc_12345678901234567890123456"
             }) ==
               %{
                 "success" => false,
                 "version" => "1",
                 "data" => %{
                   "object" => "error",
                   "code" => "unauthorized",
                   "description" => "You are not allowed to perform the requested operation",
                   "messages" => nil
                 }
               }
    end

    test "returns invalid_parameter error if account id is not provided" do
      assert admin_user_request("/account.get_members", %{}) ==
               %{
                 "success" => false,
                 "version" => "1",
                 "data" => %{
                   "object" => "error",
                   "code" => "client:invalid_parameter",
                   "description" => "Invalid parameter provided",
                   "messages" => nil
                 }
               }
    end
  end

  describe "/account.assign_user" do
    test "returns empty success if assigned with user_id successfully" do
      response =
        admin_user_request("/account.assign_user", %{
          user_id: insert(:user).id,
          account_id: insert(:account).id,
          role_name: insert(:role).name,
          redirect_url: @redirect_url
        })

      assert response["success"] == true
      assert response["data"] == %{}
    end

    test "returns empty success if assigned with email successfully" do
      response =
        admin_user_request("/account.assign_user", %{
          email: insert(:admin).email,
          account_id: insert(:account).id,
          role_name: insert(:role).name,
          redirect_url: @redirect_url
        })

      assert response["success"] == true
      assert response["data"] == %{}
    end

    test "returns an error if the email format is invalid" do
      response =
        admin_user_request("/account.assign_user", %{
          email: "invalid_format",
          account_id: insert(:account).id,
          role_name: insert(:role).name,
          redirect_url: @redirect_url
        })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:invalid_email"
      assert response["data"]["description"] == "The format of the provided email is invalid."
    end

    test "returns an error if the email is nil" do
      response =
        admin_user_request("/account.assign_user", %{
          email: nil,
          account_id: insert(:account).id,
          role_name: insert(:role).name,
          redirect_url: @redirect_url
        })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:invalid_email"
      assert response["data"]["description"] == "The format of the provided email is invalid."
    end

    test "returns client:invalid_parameter error if the redirect_url is not allowed" do
      redirect_url = "http://unknown-url.com/invite?email={email}&token={token}"

      response =
        admin_user_request("/account.assign_user", %{
          email: "wrong.redirect.url@example.com",
          account_id: insert(:account).id,
          role_name: insert(:role).name,
          redirect_url: redirect_url
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "The `redirect_url` is not allowed to be used. Got: #{redirect_url}"
    end

    test "returns an error if the given user id does not exist" do
      response =
        admin_user_request("/account.assign_user", %{
          user_id: UUID.generate(),
          account_id: insert(:account).id,
          role_name: insert(:role).name,
          redirect_url: @redirect_url
        })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:id_not_found"

      assert response["data"]["description"] ==
               "There is no user corresponding to the provided id"
    end

    test "returns an error if the given account id does not exist" do
      response =
        admin_user_request("/account.assign_user", %{
          user_id: insert(:user).id,
          account_id: "acc_12345678901234567890123456",
          role_name: insert(:role).name,
          redirect_url: @redirect_url
        })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end

    test "returns an error if the given role does not exist" do
      response =
        admin_user_request("/account.assign_user", %{
          user_id: insert(:user).id,
          account_id: insert(:account).id,
          role_name: "invalid_role",
          redirect_url: @redirect_url
        })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "role:name_not_found"

      assert response["data"]["description"] ==
               "There is no role corresponding to the provided name"
    end
  end

  describe "/account.unassign_user" do
    test "returns empty success if unassigned successfully" do
      account = insert(:account)
      user = insert(:user)
      _membership = insert(:membership, %{account: account, user: user})

      response =
        admin_user_request("/account.unassign_user", %{
          user_id: user.id,
          account_id: account.id
        })

      assert response["success"] == true
      assert response["data"] == %{}
    end

    test "returns an error if the user was not previously assigned to the account" do
      user = insert(:user)
      account = insert(:account)

      response =
        admin_user_request("/account.unassign_user", %{
          user_id: user.id,
          account_id: account.id
        })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "membership:not_found"
      assert response["data"]["description"] == "The user is not assigned to the provided account"
    end

    test "returns an error if the given user id does not exist" do
      response =
        admin_user_request("/account.unassign_user", %{
          user_id: UUID.generate(),
          account_id: insert(:account).id
        })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:id_not_found"

      assert response["data"]["description"] ==
               "There is no user corresponding to the provided id"
    end

    test "returns an error if the given account id does not exist" do
      response =
        admin_user_request("/account.unassign_user", %{
          user_id: insert(:user).id,
          account_id: "acc_12345678901234567890123456"
        })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end
  end
end
