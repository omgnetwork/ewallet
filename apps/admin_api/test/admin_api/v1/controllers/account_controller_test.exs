defmodule AdminAPI.V1.AccountControllerTest do
  use AdminAPI.ConnCase, async: true
  alias Ecto.UUID
  alias EWallet.Web.Date
  alias EWalletDB.User

  describe "/account.all" do
    test "returns a list of accounts and pagination data" do
      response = user_request("/account.all")

      # Asserts return data
      assert response["success"]
      assert response["data"]["object"] == "list"
      assert is_list(response["data"]["data"])

      # Asserts pagination data
      pagination = response["data"]["pagination"]
      assert is_integer pagination["per_page"]
      assert is_integer pagination["current_page"]
      assert is_boolean pagination["is_last_page"]
      assert is_boolean pagination["is_first_page"]
    end

    test "returns a list of accounts according to search_term, sort_by and sort_direction" do
      insert(:account, %{name: "Matched 2"})
      insert(:account, %{name: "Matched 3"})
      insert(:account, %{name: "Matched 1"})
      insert(:account, %{name: "Missed 1"})

      attrs = %{
        "search_term" => "MaTcHed", # Search is case-insensitive
        "sort_by" => "name",
        "sort_dir" => "desc"
      }

      response = user_request("/account.all", attrs)
      accounts = response["data"]["data"]

      assert response["success"]
      assert Enum.count(accounts) == 3
      assert Enum.at(accounts, 0)["name"] == "Matched 3"
      assert Enum.at(accounts, 1)["name"] == "Matched 2"
      assert Enum.at(accounts, 2)["name"] == "Matched 1"
    end
  end

  describe "/account.get" do
    test "returns an account by the given account's ID" do
      accounts  = insert_list(3, :account)
      target    = Enum.at(accounts, 1) # Pick the 2nd inserted account
      response  = user_request("/account.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "account"
      assert response["data"]["name"] == target.name
    end

    test "returns 'account:id_not_found' if the given ID was not found" do
      response  = user_request("/account.get", %{"id" => "00000000-0000-0000-0000-000000000000"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "account:id_not_found"
      assert response["data"]["description"] == "There is no account corresponding to the provided id"
    end

    test "returns 'account:id_not_found' if the given ID is not UUID" do
      response  = user_request("/account.get", %{"id" => "not_uuid"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "account:id_not_found"
      assert response["data"]["description"] == "There is no account corresponding to the provided id"
    end
  end

  describe "/account.create" do
    test "creates a new account and returns it" do
      request_data = params_for(:account)
      response     = user_request("/account.create", request_data)

      assert response["success"] == true
      assert response["data"]["object"] == "account"
      assert response["data"]["name"] == request_data.name
    end

    test "returns an error if account name is not provided" do
      request_data = params_for(:account, %{name: ""})
      response     = user_request("/account.create", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
    end
  end

  describe "/account.update" do
    test "updates the given account" do
      account = insert(:account)

      # Prepare the update data while keeping only id the same
      request_data = params_for(:account, %{
        id: account.id,
        name: "updated_name",
        description: "updated_description"
      })

      response = user_request("/account.update", request_data)

      assert response["success"] == true
      assert response["data"]["object"] == "account"
      assert response["data"]["name"] == "updated_name"
      assert response["data"]["description"] == "updated_description"
    end

    test "returns an error if id is not provided" do
      request_data = params_for(:account, %{id: ""})
      response     = user_request("/account.update", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided"
    end
  end

  describe "/account.list_users" do
    test "returns a list of users with role and status" do
      account = insert(:account)
      user    = insert(:user)
      role    = insert(:role)
      _       = insert(:membership, %{account: account, user: user, role: role})

      assert user_request("/account.list_users", %{account_id: account.id}) ==
        %{
          "version" => "1",
          "success" => true,
          "data" => %{
            "object" => "list",
            "data" => [%{
              "object" => "user",
              "id" => user.id,
              "username" => user.username,
              "provider_user_id" => user.provider_user_id,
              "email" => user.email,
              "metadata" => user.metadata,
              "avatar" => %{
                "original" => nil
              },
              "created_at" => Date.to_iso8601(user.inserted_at),
              "updated_at" => Date.to_iso8601(user.updated_at),
              "account_role" => role.name,
              "status" => to_string(User.get_status(user))
            }]
          }
        }
    end

    test "returns an empty list if account has no users" do
      account = insert(:account)

      assert user_request("/account.list_users", %{account_id: account.id}) ==
        %{
          "version" => "1",
          "success" => true,
          "data" => %{
            "object" => "list",
            "data" => []
          }
        }
    end

    test "returns account:id_not_found error if account id could not be found" do
      assert user_request("/account.list_users", %{account_id: UUID.generate()}) ==
        %{
          "success" => false,
          "version" => "1",
          "data" => %{
            "object" => "error",
            "code" => "account:id_not_found",
            "description" => "There is no account corresponding to the provided id",
            "messages" => nil
          }
        }
    end

    test "returns invalid_parameter error if account id is not provided" do
      assert user_request("/account.list_users", %{some_other_id: UUID.generate()}) ==
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
    test "returns empty success if assigned successfully" do
      response = user_request("/account.assign_user", %{
        user_id: insert(:user).id,
        account_id: insert(:account).id,
        role_name: insert(:role).name
      })

      assert response["success"] == true
      assert response["data"] == %{}
    end

    test "returns an error if the given user id does not exist" do
      response = user_request("/account.assign_user", %{
        user_id: UUID.generate(),
        account_id: insert(:account).id,
        role_name: insert(:role).name
      })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "The given user id could not be found."
    end

    test "returns an error if the given account id does not exist" do
      response = user_request("/account.assign_user", %{
        user_id: insert(:user).id,
        account_id: UUID.generate(),
        role_name: insert(:role).name
      })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "The given account id could not be found."
    end

    test "returns an error if the given role does not exist" do
      response = user_request("/account.assign_user", %{
        user_id: insert(:user).id,
        account_id: insert(:account).id,
        role_name: "invalid_role"
      })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "The given role name could not be found."
    end
  end

  describe "/account.unassign_user" do
    test "returns empty success if unassigned successfully" do
      membership = insert(:membership)
      response   = user_request("/account.unassign_user", %{
        user_id: membership.user_id,
        account_id: membership.account_id
      })

      assert response["success"] == true
      assert response["data"] == %{}
    end

    test "returns an error if the user was not previously assigned to the account" do
      user    = insert(:user)
      account = insert(:account)

      response = user_request("/account.unassign_user", %{
        user_id: user.id,
        account_id: account.id
      })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "The user was not assigned to this account."
    end

    test "returns an error if the given user id does not exist" do
      response = user_request("/account.unassign_user", %{
        user_id: UUID.generate(),
        account_id: insert(:account).id
      })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "The given user id could not be found."
    end

    test "returns an error if the given account id does not exist" do
      response = user_request("/account.unassign_user", %{
        user_id: insert(:user).id,
        account_id: UUID.generate()
      })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "The given account id could not be found."
    end
  end

  describe "/account.upload_avatar" do
    test "uploads an avatar for the specified user" do
      account = insert(:account)

      response = user_request("/account.upload_avatar", %{
        "id" => account.id,
        "avatar" => %Plug.Upload{
          path: "test/support/assets/test.jpg",
          filename: "test.jpg"
        }
      })

      assert response["success"]
      assert response["data"]["object"] == "account"
      assert response["data"]["avatar"]["original"] =~ "http://example.com/public/uploads/test/account/avatars/#{account.id}/original.jpg?v="
    end

    test "returns 'account:id_not_found' if the given ID was not found" do
      response = user_request("/account.upload_avatar", %{
        "id" => "fake",
        "avatar" => %Plug.Upload{
          path: "test/support/assets/test.jpg",
          filename: "test.jpg"
        }
      })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "account:id_not_found"
      assert response["data"]["description"] == "There is no account corresponding to the provided id"
    end
  end
end
