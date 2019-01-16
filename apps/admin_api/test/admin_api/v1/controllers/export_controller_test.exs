# Copyright 2018 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule AdminAPI.V1.ExportControllerTest do
  use AdminAPI.ConnCase, async: true

  describe "/export.all" do
    test_with_auths "returns a list of exports and pagination data" do
      response = request("/export.all")

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

    test_with_auths "returns a list of exports according to search_term, sort_by and sort_direction" do
      user = get_test_admin()
      key = get_test_key()
      insert(:export, %{filename: "Matched 2", user_uuid: user.uuid, key_uuid: key.uuid})
      insert(:export, %{filename: "Matched 3", user_uuid: user.uuid, key_uuid: key.uuid})
      insert(:export, %{filename: "Matched 1", user_uuid: user.uuid, key_uuid: key.uuid})
      insert(:export, %{filename: "Missed 1", user_uuid: user.uuid, key_uuid: key.uuid})

      attrs = %{
        # Search is case-insensitive
        "search_term" => "MaTcHed",
        "sort_by" => "filename",
        "sort_dir" => "desc"
      }

      response = request("/export.all", attrs)
      exports = response["data"]["data"]

      assert response["success"]
      assert Enum.count(exports) == 3
      assert Enum.at(exports, 0)["filename"] == "Matched 3"
      assert Enum.at(exports, 1)["filename"] == "Matched 2"
      assert Enum.at(exports, 2)["filename"] == "Matched 1"
    end

    test_with_auths "does not return exports not owned" do
      insert(:export)
      insert(:export)
      insert(:export)

      response = request("/export.all", %{})
      exports = response["data"]["data"]

      assert response["success"]
      assert Enum.empty?(exports)
    end
  end

  describe "/export.get" do
    test_with_auths "returns an export by the given export's ID" do
      user = get_test_admin()
      key = get_test_key()
      exports = insert_list(3, :export, user_uuid: user.uuid, key_uuid: key.uuid)

      # Pick the 2nd inserted export
      target = Enum.at(exports, 1)
      response = request("/export.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "export"
      assert response["data"]["filename"] == target.filename
    end

    test_with_auths "returns 'unauthorized' if the export is not owned" do
      export = insert(:export)
      response = request("/export.get", %{"id" => export.id})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"

      assert response["data"]["description"] ==
               "You are not allowed to perform the requested operation."
    end

    test_with_auths "returns 'unauthorized' if the given ID was not found" do
      response = request("/export.get", %{"id" => "exp_12345678901234567890123456"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"

      assert response["data"]["description"] ==
               "You are not allowed to perform the requested operation."
    end

    test_with_auths "returns 'unauthorized' if the given ID format is invalid" do
      response = request("/export.get", %{"id" => "not_an_id"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"

      assert response["data"]["description"] ==
               "You are not allowed to perform the requested operation."
    end
  end

  describe "/export.download" do
    test_with_auths "returns a 'file:not_found' error when the file does not exist" do
      user = get_test_admin()
      key = get_test_key()
      exports = insert_list(3, :export, user_uuid: user.uuid, key_uuid: key.uuid)

      # Pick the 2nd inserted export
      target = Enum.at(exports, 1)
      response = request("/export.download", %{"id" => target.id})

      refute response["success"]
      assert response["data"]["code"] == "file:not_found"
      assert response["data"]["description"] == "The file could not be found on the server."
    end

    test_with_auths "returns an 'export:not_local' error when the given export uses a non-local adapter" do
      user = get_test_admin()
      key = get_test_key()
      export = insert(:export, user_uuid: user.uuid, key_uuid: key.uuid, adapter: "gcs")

      response = request("/export.download", %{"id" => export.id})

      refute response["success"]
      assert response["data"]["code"] == "export:not_local"
      assert response["data"]["description"] == "The given export is not stored locally."
    end

    test_with_auths "returns 'unauthorized' if the export is not owned" do
      export = insert(:export)
      response = request("/export.get", %{"id" => export.id})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"

      assert response["data"]["description"] ==
               "You are not allowed to perform the requested operation."
    end

    test_with_auths "returns 'unauthorized' if the given ID was not found" do
      response = request("/export.get", %{"id" => "exp_12345678901234567890123456"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"

      assert response["data"]["description"] ==
               "You are not allowed to perform the requested operation."
    end

    test_with_auths "returns 'unauthorized' if the given ID format is invalid" do
      response = request("/export.get", %{"id" => "not_an_id"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"

      assert response["data"]["description"] ==
               "You are not allowed to perform the requested operation."
    end
  end
end
