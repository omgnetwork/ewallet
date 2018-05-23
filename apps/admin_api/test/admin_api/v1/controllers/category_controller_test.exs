defmodule AdminAPI.V1.CategoryControllerTest do
  use AdminAPI.ConnCase, async: true

  describe "/category.all" do
    test "returns a list of categories and pagination data" do
      response = user_request("/category.all")

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

      response = user_request("/category.all", attrs)
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
      response = user_request("/category.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "category"
      assert response["data"]["name"] == target.name
    end

    test "returns 'category:id_not_found' if the given ID was not found" do
      response = user_request("/category.get", %{"id" => "cat_12345678901234567890123456"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "category:id_not_found"

      assert response["data"]["description"] ==
               "There is no category corresponding to the provided id"
    end

    test "returns 'category:id_not_found' if the given ID format is invalid" do
      response = user_request("/category.get", %{"id" => "not_an_id"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "category:id_not_found"

      assert response["data"]["description"] ==
               "There is no category corresponding to the provided id"
    end
  end
end
