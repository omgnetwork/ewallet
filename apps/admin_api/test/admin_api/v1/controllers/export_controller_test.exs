defmodule AdminAPI.V1.ExportControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWalletDB.{Account, Membership, Repo, Role, User}
  alias ActivityLogger.System

  describe "/export.all" do
    test "returns a list of exports and pagination data" do
      response = admin_user_request("/export.all")

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

    test "returns a list of exports according to search_term, sort_by and sort_direction" do
      user = get_test_admin()
      insert(:export, %{filename: "Matched 2", user_uuid: user.uuid})
      insert(:export, %{filename: "Matched 3", user_uuid: user.uuid})
      insert(:export, %{filename: "Matched 1", user_uuid: user.uuid})
      insert(:export, %{filename: "Missed 1", user_uuid: user.uuid})

      attrs = %{
        # Search is case-insensitive
        "search_term" => "MaTcHed",
        "sort_by" => "filename",
        "sort_dir" => "desc"
      }

      response = admin_user_request("/export.all", attrs)
      exports = response["data"]["data"]

      assert response["success"]
      assert Enum.count(exports) == 3
      assert Enum.at(exports, 0)["filename"] == "Matched 3"
      assert Enum.at(exports, 1)["filename"] == "Matched 2"
      assert Enum.at(exports, 2)["filename"] == "Matched 1"
    end

    test "does not return exports not owned" do
      insert(:export)
      insert(:export)
      insert(:export)

      response = admin_user_request("/export.all", %{})
      exports = response["data"]["data"]

      assert response["success"]
      assert Enum.count(exports) == 0
    end
  end

  describe "/export.get" do
    test "returns an export by the given export's ID" do
      user = get_test_admin()
      exports = insert_list(3, :export, user_uuid: user.uuid)

      # Pick the 2nd inserted export
      target = Enum.at(exports, 1)
      response = admin_user_request("/export.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "export"
      assert response["data"]["filename"] == target.filename
    end

    test "returns a download URL" do
      user = get_test_admin()
      exports = insert_list(3, :export, user_uuid: user.uuid)

      # Pick the 2nd inserted export
      target = Enum.at(exports, 1)
      response = admin_user_request("/export.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "export"
      assert response["data"]["filename"] == target.filename
      assert response["data"]["url"] != nil
    end

    test "returns 'unauthorized' if the export is not owned" do
      export = insert(:export)
      response = admin_user_request("/export.get", %{"id" => export.id})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"

      assert response["data"]["description"] ==
               "You are not allowed to perform the requested operation."
    end

    test "returns 'unauthorized' if the given ID was not found" do
      response = admin_user_request("/export.get", %{"id" => "exp_12345678901234567890123456"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"

      assert response["data"]["description"] ==
               "You are not allowed to perform the requested operation."
    end

    test "returns 'unauthorized' if the given ID format is invalid" do
      response = admin_user_request("/export.get", %{"id" => "not_an_id"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"

      assert response["data"]["description"] ==
               "You are not allowed to perform the requested operation."
    end
  end
end
