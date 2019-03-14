# Copyright 2018-2019 OmiseGO Pte Ltd
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

defmodule AdminAPI.V1.PermissionControllerTest do
  use AdminAPI.ConnCase, async: true

  describe "/permission.all" do
    test_with_auths "returns all permissions separated by global_roles and account_roles maps" do
      response = request("/permission.all")

      assert response["success"]
      assert response["data"]["object"] == "permissions"

      assert Map.has_key?(response["data"], "global_roles")
      assert Map.has_key?(response["data"], "account_roles")

      assert is_map(response["data"]["global_roles"])
      assert is_map(response["data"]["account_roles"])
    end

    test "returns :invalid_auth_scheme error when the request is not authenticated" do
      response = unauthenticated_request("/permission.all")

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_auth_scheme"

      assert response["data"]["description"] ==
               "The provided authentication scheme is not supported."
    end
  end
end
