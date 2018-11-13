defmodule AdminAPI.V1.ProviderAuth.CategoryControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWalletDB.Category
  alias EWalletDB.Helpers.Preloader

  describe "/category.all" do
    test "returns a list of categories and pagination data" do
      response = provider_request("/category.all")

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

    test "returns a list of categories according to search_term, sort_by and sort_direction" do
      insert(:category, %{name: "Matched 2"})
      insert(:category, %{name: "Matched 3"})
      insert(:category, %{name: "Matched 1"})
      insert(:category, %{name: "Missed 1"})

      attrs = %{
        # Search is case-insensitive
        "search_term" => "MaTcHed",
        "sort_by" => "name",
        "sort_dir" => "desc"
      }

      response = provider_request("/category.all", attrs)
      categories = response["data"]["data"]

      assert response["success"]
      assert Enum.count(categories) == 3
      assert Enum.at(categories, 0)["name"] == "Matched 3"
      assert Enum.at(categories, 1)["name"] == "Matched 2"
      assert Enum.at(categories, 2)["name"] == "Matched 1"
    end
  end

  describe "/category.get" do
    test "returns an category by the given category's ID" do
      categories = insert_list(3, :category)

      # Pick the 2nd inserted category
      target = Enum.at(categories, 1)
      response = provider_request("/category.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "category"
      assert response["data"]["name"] == target.name
    end

    test "returns 'category:id_not_found' if the given ID was not found" do
      response = provider_request("/category.get", %{"id" => "cat_12345678901234567890123456"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "category:id_not_found"

      assert response["data"]["description"] ==
               "There is no category corresponding to the provided id."
    end

    test "returns 'category:id_not_found' if the given ID format is invalid" do
      response = provider_request("/category.get", %{"id" => "not_an_id"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "category:id_not_found"

      assert response["data"]["description"] ==
               "There is no category corresponding to the provided id."
    end
  end

  describe "/category.create" do
    test "creates a new category and returns it" do
      request_data = %{name: "A test category"}
      response = provider_request("/category.create", request_data)

      assert response["success"] == true
      assert response["data"]["object"] == "category"
      assert response["data"]["name"] == request_data.name
    end

    test "returns an error if the category name is not provided" do
      request_data = %{name: ""}
      response = provider_request("/category.create", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
    end
  end

  describe "/category.update" do
    test "updates the given category" do
      category = insert(:category)

      # Prepare the update data while keeping only id the same
      request_data =
        params_for(:category, %{
          id: category.id,
          name: "updated_name",
          description: "updated_description"
        })

      response = provider_request("/category.update", request_data)

      assert response["success"] == true
      assert response["data"]["object"] == "category"
      assert response["data"]["name"] == "updated_name"
      assert response["data"]["description"] == "updated_description"
    end

    test "updates the category's accounts" do
      category = :category |> insert() |> Preloader.preload(:accounts)
      account = :account |> insert()
      assert Enum.empty?(category.accounts)

      # Prepare the update data while keeping only id the same
      request_data = %{
        id: category.id,
        account_ids: [account.id]
      }

      response = provider_request("/category.update", request_data)

      assert response["success"] == true
      assert response["data"]["object"] == "category"
      assert response["data"]["account_ids"] == [account.id]
      assert List.first(response["data"]["accounts"]["data"])["id"] == account.id
    end

    test "returns a 'client:invalid_parameter' error if id is not provided" do
      request_data = params_for(:category, %{id: nil})
      response = provider_request("/category.update", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided."
    end

    test "returns an 'unauthorized' error if id is invalid" do
      request_data = params_for(:category, %{id: "invalid_format"})
      response = provider_request("/category.update", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "category:id_not_found"

      assert response["data"]["description"] ==
               "There is no category corresponding to the provided id."
    end
  end

  describe "/category.delete" do
    test "responds success with the deleted category" do
      category = insert(:category)
      response = provider_request("/category.delete", %{id: category.id})

      assert response["success"] == true
      assert response["data"]["object"] == "category"
      assert response["data"]["id"] == category.id
    end

    test "responds with an error if the category has one or more associated accounts" do
      account = insert(:account)

      {:ok, category} =
        :category
        |> insert()
        |> Category.update(%{account_ids: [account.id]})

      response = admin_user_request("/category.delete", %{id: category.id})

      assert response ==
               %{
                 "version" => "1",
                 "success" => false,
                 "data" => %{
                   "code" => "category:not_empty",
                   "description" => "The category has one or more accounts associated.",
                   "messages" => nil,
                   "object" => "error"
                 }
               }
    end

    test "responds with an error if the provided id is not found" do
      response = provider_request("/category.delete", %{id: "wrong_id"})

      assert response ==
               %{
                 "version" => "1",
                 "success" => false,
                 "data" => %{
                   "code" => "category:id_not_found",
                   "description" => "There is no category corresponding to the provided id.",
                   "messages" => nil,
                   "object" => "error"
                 }
               }
    end

    test "responds with an error if the user is not authorized to delete the category" do
      category = insert(:category)
      key = insert(:key)

      attrs = %{id: category.id}
      opts = [access_key: key.access_key, secret_key: key.secret_key]
      response = provider_request("/category.delete", attrs, opts)

      assert response ==
               %{
                 "version" => "1",
                 "success" => false,
                 "data" => %{
                   "code" => "unauthorized",
                   "description" => "You are not allowed to perform the requested operation.",
                   "messages" => nil,
                   "object" => "error"
                 }
               }
    end
  end
end
