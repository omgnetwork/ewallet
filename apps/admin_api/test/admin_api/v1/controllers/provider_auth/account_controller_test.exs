defmodule AdminAPI.V1.ProviderAuth.AccountControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWalletDB.{Account, Repo, User}

  describe "/account.all" do
    test "returns a list of accounts and pagination data" do
      response = provider_request("/account.all")

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

      response = provider_request("/account.all", attrs)
      accounts = response["data"]["data"]

      assert response["success"]
      assert Enum.count(accounts) == 3
      assert Enum.at(accounts, 0)["name"] == "Matched 3"
      assert Enum.at(accounts, 1)["name"] == "Matched 2"
      assert Enum.at(accounts, 2)["name"] == "Matched 1"
    end
  end

  describe "/account.get" do
    test "returns an account by the given account's external ID" do
      accounts = insert_list(3, :account)
      # Pick the 2nd inserted account
      target = Enum.at(accounts, 1)
      response = provider_request("/account.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "account"
      assert response["data"]["name"] == target.name
    end

    # The user should not know any information about the account it doesn't have access to.
    # So even the account is not found, the user is unauthorized to know that.
    test "returns 'account:id_not_found' if the given ID is in correct format but not found" do
      response = provider_request("/account.get", %{"id" => "acc_00000000000000000000000000"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "account:id_not_found"
    end

    test "returns 'account:id_not_found' if the given ID is not in the correct format" do
      response = provider_request("/account.get", %{"id" => "invalid_format"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "account:id_not_found"
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

      response = provider_request("/account.create", request_data)

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

      response = provider_request("/account.create", request_data)

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
      response = provider_request("/account.create", request_data)

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

      response = provider_request("/account.update", request_data)

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

      response = provider_request("/account.update", request_data)

      assert response["success"] == true
      assert response["data"]["object"] == "account"
      assert response["data"]["category_ids"] == [category.id]
      assert List.first(response["data"]["categories"]["data"])["id"] == category.id
    end

    test "returns a 'client:invalid_parameter' error if id is not provided" do
      request_data = params_for(:account, %{id: nil})
      response = provider_request("/account.update", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided"
    end

    test "returns a 'user:unauthorized' error if id is invalid" do
      request_data = params_for(:account, %{id: "invalid_format"})
      response = provider_request("/account.update", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "account:id_not_found"
    end
  end

  describe "/account.upload_avatar" do
    test "uploads an avatar for the specified account" do
      account = insert(:account)

      response =
        provider_request("/account.upload_avatar", %{
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

    test "removes the avatar from an account" do
      account = insert(:account)

      response =
        provider_request("/account.upload_avatar", %{
          "id" => account.id,
          "avatar" => %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        })

      assert response["success"]

      response =
        provider_request("/account.upload_avatar", %{
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
        provider_request("/account.upload_avatar", %{
          "id" => account.id,
          "avatar" => %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        })

      assert response["success"]

      response =
        provider_request("/account.upload_avatar", %{
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
        provider_request("/account.upload_avatar", %{
          "id" => account.id,
          "avatar" => %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        })

      assert response["success"]

      response =
        provider_request("/account.upload_avatar", %{
          "id" => account.id,
          "avatar" => "null"
        })

      assert response["success"]

      account = Account.get(account.id)
      assert account.avatar == nil
    end

    test "returns 'account:id_not_found' if the given account ID was not found" do
      response =
        provider_request("/account.upload_avatar", %{
          "id" => "fake",
          "avatar" => %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "account:id_not_found"
    end
  end
end
