defmodule AdminAPI.V1.AdminAuth.AccountControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWalletDB.{Account, Membership, Repo, Role, User}

  describe "/account.all" do
    test "returns a list of accounts and pagination data" do
      response = admin_user_request("/account.all")

      # Asserts return data
      assert response["success"]
      assert response["data"]["object"] == "list"
      assert is_list(response["data"]["data"])

      # Asserts pagination data
      pagination = response["data"]["pagination"]
      assert is_integer(pagination["per_page"])
      assert is_integer(pagination["current_page"])
      assert is_boolean(pagination["is_last_page"])
      assert is_boolean(pagination["is_first_page"])
    end

    test "returns a list of accounts according to search_term, sort_by and sort_direction" do
      insert(:account, %{name: "Matched 2"})
      insert(:account, %{name: "Matched 3"})
      insert(:account, %{name: "Matched 1"})
      insert(:account, %{name: "Missed 1"})

      attrs = %{
        # Search is case-insensitive
        "search_term" => "MaTcHed",
        "sort_by" => "name",
        "sort_dir" => "desc"
      }

      response = admin_user_request("/account.all", attrs)
      accounts = response["data"]["data"]

      assert response["success"]
      assert Enum.count(accounts) == 3
      assert Enum.at(accounts, 0)["name"] == "Matched 3"
      assert Enum.at(accounts, 1)["name"] == "Matched 2"
      assert Enum.at(accounts, 2)["name"] == "Matched 1"
    end

    test_supports_match_any("/account.all", :admin_auth, :account, :name)
    test_supports_match_all("/account.all", :admin_auth, :account, :name)

    test "returns a list of accounts that the current user can access" do
      master = Account.get_master_account()
      user = get_test_admin()
      {:ok, _m} = Membership.unassign(user, master)

      role = Role.get_by(name: "admin")

      acc_1 = insert(:account, parent: master, name: "Account 1")
      acc_2 = insert(:account, parent: acc_1, name: "Account 2")
      acc_3 = insert(:account, parent: acc_2, name: "Account 3")
      _acc_4 = insert(:account, parent: acc_3, name: "Account 4")
      _acc_5 = insert(:account, parent: acc_3, name: "Account 5")

      # We add user to acc_2, so he should have access to
      # acc_2 and its descendants: acc_3, acc_4, acc_5
      {:ok, _m} = Membership.assign(user, acc_2, role)

      response = admin_user_request("/account.all", %{})
      accounts = response["data"]["data"]

      assert response["success"]
      assert Enum.count(accounts) == 4
      assert Enum.any?(accounts, fn account -> account["name"] == "Account 2" end)
      assert Enum.any?(accounts, fn account -> account["name"] == "Account 3" end)
      assert Enum.any?(accounts, fn account -> account["name"] == "Account 4" end)
      assert Enum.any?(accounts, fn account -> account["name"] == "Account 5" end)
    end

    test "returns only one account if the user is at the last level" do
      master = Account.get_master_account()
      user = get_test_admin()
      {:ok, _m} = Membership.unassign(user, master)

      role = Role.get_by(name: "admin")

      acc_1 = insert(:account, parent: master, name: "Account 1")
      acc_2 = insert(:account, parent: acc_1, name: "Account 2")
      acc_3 = insert(:account, parent: acc_2, name: "Account 3")
      _acc_4 = insert(:account, parent: acc_3, name: "Account 4")
      acc_5 = insert(:account, parent: acc_3, name: "Account 5")

      {:ok, _m} = Membership.assign(user, acc_5, role)

      response = admin_user_request("/account.all", %{})
      accounts = response["data"]["data"]

      assert response["success"]
      assert Enum.count(accounts) == 1
      assert Enum.at(accounts, 0)["name"] == "Account 5"
    end
  end

  describe "/account.get_descendants" do
    test "returns a list of baby accounts and pagination data" do
      account = Account.get_master_account()
      response = admin_user_request("/account.get_descendants", %{id: account.id})

      # Asserts return data
      assert response["success"]
      assert response["data"]["object"] == "list"
      assert is_list(response["data"]["data"])

      # Asserts pagination data
      pagination = response["data"]["pagination"]
      assert is_integer(pagination["per_page"])
      assert is_integer(pagination["current_page"])
      assert is_boolean(pagination["is_last_page"])
      assert is_boolean(pagination["is_first_page"])
    end

    test "returns a list of baby accounts" do
      _account_1 = insert(:account, name: "account_1")
      account_2 = insert(:account, name: "account_2")
      account_3 = insert(:account, parent: account_2, name: "account_3")
      _account_4 = insert(:account, parent: account_3, name: "account_4")

      attrs = %{
        "id" => account_2.id,
        "sort_by" => "name",
        "sort_dir" => "desc"
      }

      response = admin_user_request("/account.get_descendants", attrs)
      accounts = response["data"]["data"]

      assert response["success"]
      assert Enum.count(accounts) == 3
      assert Enum.at(accounts, 0)["name"] == "account_4"
      assert Enum.at(accounts, 1)["name"] == "account_3"
      assert Enum.at(accounts, 2)["name"] == "account_2"
    end

    test "returns a list of accounts according to search_term, sort_by and sort_direction" do
      _account_1 = insert(:account, name: "account_1")
      account_2 = insert(:account, name: "account_2:matchez")
      account_3 = insert(:account, parent: account_2, name: "account_3:MaTcHed")
      _account_4 = insert(:account, parent: account_3, name: "account_4:MaTcHed")

      attrs = %{
        "id" => account_2.id,
        "search_term" => "MaTcHed",
        "sort_by" => "name",
        "sort_dir" => "desc"
      }

      response = admin_user_request("/account.get_descendants", attrs)
      accounts = response["data"]["data"]

      assert response["success"]
      assert Enum.count(accounts) == 2
      assert Enum.at(accounts, 0)["name"] == "account_4:MaTcHed"
      assert Enum.at(accounts, 1)["name"] == "account_3:MaTcHed"
    end
  end

  describe "/account.get" do
    test "returns an account by the given account's external ID if the user has
          an indirect membership" do
      account = insert(:account)
      accounts = insert_list(3, :account, parent: account)
      # Pick the 2nd inserted account
      target = Enum.at(accounts, 1)
      response = admin_user_request("/account.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "account"
      assert response["data"]["name"] == target.name
    end

    test "returns an account by the given account's external ID if the user has
          a direct membership" do
      master = Account.get_master_account()
      user = get_test_admin()
      role = Role.get_by(name: "admin")

      {:ok, _m} = Membership.unassign(user, master)
      accounts = insert_list(3, :account)

      # Pick the 2nd inserted account
      target = Enum.at(accounts, 1)
      Membership.assign(user, target, role)
      response = admin_user_request("/account.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "account"
      assert response["data"]["name"] == target.name
    end

    test "gets unauthorized if the user doesn't have access" do
      master = Account.get_master_account()
      user = get_test_admin()
      {:ok, _m} = Membership.unassign(user, master)
      accounts = insert_list(3, :account)
      # Pick the 2nd inserted account
      target = Enum.at(accounts, 1)
      response = admin_user_request("/account.get", %{"id" => target.id})

      refute response["success"]
      assert response["data"]["code"] == "unauthorized"
    end

    # The user should not know any information about the account it doesn't have access to.
    # So even the account is not found, the user is unauthorized to know that.
    test "returns 'unauthorized' if the given ID is in correct format but not found" do
      response = admin_user_request("/account.get", %{"id" => "acc_00000000000000000000000000"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"

      assert response["data"]["description"] ==
               "You are not allowed to perform the requested operation."
    end

    test "returns 'client:invalid_parameter' if the given ID is not in the correct format" do
      response = admin_user_request("/account.get", %{"id" => "invalid_format"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"

      assert response["data"]["description"] ==
               "You are not allowed to perform the requested operation."
    end
  end

  describe "/account.create" do
    test "creates a new account and returns it" do
      parent = User.get_account(get_test_admin())

      request_data = %{
        parent_id: parent.id,
        name: "A test account",
        metadata: %{something: "interesting"},
        encrypted_metadata: %{something: "secret"}
      }

      response = admin_user_request("/account.create", request_data)

      assert response["success"] == true
      assert response["data"]["object"] == "account"
      assert response["data"]["name"] == request_data.name
      assert response["data"]["parent_id"] == parent.id
      assert response["data"]["metadata"] == %{"something" => "interesting"}
      assert response["data"]["encrypted_metadata"] == %{"something" => "secret"}
    end

    test "creates a new account with no parent_id" do
      parent = Account.get_master_account()

      request_data = %{
        parent_id: parent.id,
        metadata: %{something: "interesting"},
        name: "A test account",
        encrypted_metadata: %{something: "secret"}
      }

      response = admin_user_request("/account.create", request_data)

      assert response["success"] == true
      assert response["data"]["object"] == "account"
      assert response["data"]["name"] == request_data.name
      assert response["data"]["parent_id"] == parent.id
      assert response["data"]["metadata"] == %{"something" => "interesting"}
      assert response["data"]["encrypted_metadata"] == %{"something" => "secret"}
    end

    test "returns an error if account name is not provided" do
      parent = User.get_account(get_test_admin())
      request_data = %{name: "", parent_id: parent.id}
      response = admin_user_request("/account.create", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
    end
  end

  describe "/account.update" do
    test "updates the given account" do
      account = User.get_account(get_test_admin())

      # Prepare the update data while keeping only id the same
      request_data =
        params_for(:account, %{
          id: account.id,
          name: "updated_name",
          description: "updated_description"
        })

      response = admin_user_request("/account.update", request_data)

      assert response["success"] == true
      assert response["data"]["object"] == "account"
      assert response["data"]["name"] == "updated_name"
      assert response["data"]["description"] == "updated_description"
    end

    test "updates the account's categories" do
      account = :account |> insert() |> Repo.preload(:categories)
      category = :category |> insert()
      assert Enum.empty?(account.categories)

      # Prepare the update data while keeping only id the same
      request_data = %{
        id: account.id,
        category_ids: [category.id]
      }

      response = admin_user_request("/account.update", request_data)

      assert response["success"] == true
      assert response["data"]["object"] == "account"
      assert response["data"]["category_ids"] == [category.id]
      assert List.first(response["data"]["categories"]["data"])["id"] == category.id
    end

    test "returns a 'client:invalid_parameter' error if id is not provided" do
      request_data = params_for(:account, %{id: nil})
      response = admin_user_request("/account.update", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided."
    end

    test "returns a 'unauthorized' error if id is invalid" do
      request_data = params_for(:account, %{id: "invalid_format"})
      response = admin_user_request("/account.update", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"

      assert response["data"]["description"] ==
               "You are not allowed to perform the requested operation."
    end
  end

  describe "/account.upload_avatar" do
    test "uploads an avatar for the specified account" do
      account = insert(:account)

      response =
        admin_user_request("/account.upload_avatar", %{
          "id" => account.id,
          "avatar" => %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        })

      assert response["success"]
      assert response["data"]["object"] == "account"

      assert response["data"]["avatar"]["large"] =~
               "http://localhost:4000/public/uploads/test/account/avatars/#{account.id}/large.png?v="

      assert response["data"]["avatar"]["original"] =~
               "http://localhost:4000/public/uploads/test/account/avatars/#{account.id}/original.jpg?v="

      assert response["data"]["avatar"]["small"] =~
               "http://localhost:4000/public/uploads/test/account/avatars/#{account.id}/small.png?v="

      assert response["data"]["avatar"]["thumb"] =~
               "http://localhost:4000/public/uploads/test/account/avatars/#{account.id}/thumb.png?v="
    end

    test "fails to upload an invalid file" do
      account = insert(:account)

      response =
        admin_user_request("/account.upload_avatar", %{
          "id" => account.id,
          "avatar" => %Plug.Upload{
            path: "test/support/assets/file.json",
            filename: "file.json"
          }
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test "returns an error when 'avatar' is not sent" do
      account = insert(:account)

      response =
        admin_user_request("/account.upload_avatar", %{
          "id" => account.id
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test "removes the avatar from an account" do
      account = insert(:account)

      response =
        admin_user_request("/account.upload_avatar", %{
          "id" => account.id,
          "avatar" => %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        })

      assert response["success"]

      response =
        admin_user_request("/account.upload_avatar", %{
          "id" => account.id,
          "avatar" => nil
        })

      assert response["success"]

      account = Account.get(account.id)
      assert account.avatar == nil
    end

    test "removes the avatar from an account with empty string" do
      account = insert(:account)

      response =
        admin_user_request("/account.upload_avatar", %{
          "id" => account.id,
          "avatar" => %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        })

      assert response["success"]

      response =
        admin_user_request("/account.upload_avatar", %{
          "id" => account.id,
          "avatar" => ""
        })

      assert response["success"]

      account = Account.get(account.id)
      assert account.avatar == nil
    end

    test "removes the avatar from an account with 'null' string" do
      account = insert(:account)

      response =
        admin_user_request("/account.upload_avatar", %{
          "id" => account.id,
          "avatar" => %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        })

      assert response["success"]

      response =
        admin_user_request("/account.upload_avatar", %{
          "id" => account.id,
          "avatar" => "null"
        })

      assert response["success"]

      account = Account.get(account.id)
      assert account.avatar == nil
    end

    test "returns 'unauthorized' if the given account ID was not found" do
      response =
        admin_user_request("/account.upload_avatar", %{
          "id" => "fake",
          "avatar" => %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"

      assert response["data"]["description"] ==
               "You are not allowed to perform the requested operation."
    end
  end
end
