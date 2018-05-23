defmodule AdminAPI.V1.CategoryControllerTest do
  use AdminAPI.ConnCase, async: true

  describe "/category.all" do
    test "returns a list of account categories and pagination data" do
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
  end
end
