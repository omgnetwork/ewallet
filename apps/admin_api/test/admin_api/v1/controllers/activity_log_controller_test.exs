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

defmodule AdminAPI.V1.ActivityControllerTest do
  use AdminAPI.ConnCase, async: true

  describe "/activity_log.all" do
    test_with_auths "returns a list of activity_logs and pagination data" do
      response = request("/activity_log.all")

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

    test_with_auths "returns a list of activity_logs according to search_term, sort_by and sort_direction" do
      insert(:activity_log, %{action: "Matched 2"})
      insert(:activity_log, %{action: "Matched 3"})
      insert(:activity_log, %{action: "Matched 1"})
      insert(:activity_log, %{action: "Missed 1"})

      attrs = %{
        # Search is case-insensitive
        "search_term" => "MaTcHed",
        "sort_by" => "action",
        "sort_dir" => "desc"
      }

      response = request("/activity_log.all", attrs)
      activity_logs = response["data"]["data"]

      assert response["success"]
      assert Enum.count(activity_logs) == 3
      assert Enum.at(activity_logs, 0)["action"] == "Matched 3"
      assert Enum.at(activity_logs, 1)["action"] == "Matched 2"
      assert Enum.at(activity_logs, 2)["action"] == "Matched 1"
    end

    test_with_auths "returns unauthorized error if the admin is not from the master account" do
      auth_token = insert(:auth_token, owner_app: "admin_api")
      key = insert(:key)

      opts = [
        access_key: key.access_key,
        secret_key: key.secret_key,
        user_id: auth_token.user.id,
        auth_token: auth_token.token
      ]

      response =
        request(
          "/activity_log.all",
          %{},
          opts
        )

      assert response ==
               %{
                 "success" => false,
                 "version" => "1",
                 "data" => %{
                   "object" => "error",
                   "code" => "unauthorized",
                   "description" => "You are not allowed to perform the requested operation.",
                   "messages" => nil
                 }
               }
    end

    test_supports_match_any("/activity_log.all", :activity_log, :action)
    test_supports_match_all("/activity_log.all", :activity_log, :action)
  end
end
