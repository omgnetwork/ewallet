defmodule AdminAPI.V1.AdminAuth.ConfigurationControllerTest do
  use AdminAPI.ConnCase, async: true

  describe "/configuration.get" do
    test "returns a list of accounts and pagination data" do
      response = admin_user_request("/configuration.get", %{})

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

    test "returns a list of settings" do
      response = admin_user_request("/configuration.get", %{
        per_page: 100,
        sort_by: "position",
        sort_dir: "asc"
      })

      assert response["success"] == true
      assert length(response["data"]["data"]) == 19
      assert response["data"]["pagination"]["count"] == 19

      setting = Enum.at(response["data"]["data"], 0)
      assert setting["key"] == "aws_access_key_id"
      assert setting["position"] == 0
    end
  end
end
