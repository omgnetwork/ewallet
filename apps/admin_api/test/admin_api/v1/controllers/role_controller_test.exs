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

defmodule AdminAPI.V1.RoleControllerTest do
  use AdminAPI.ConnCase, async: true

  describe "/role.all" do
    test_with_auths "returns unauthorized" do
      response = request("/role.all")

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end
  end

  describe "/role.get" do
    test_with_auths "returns unauthorized" do
      response = request("/role.all")

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end
  end

  describe "/role.create" do
    test_with_auths "returns unauthorized" do
      response = request("/role.all")

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end
  end

  describe "/role.update" do
    test_with_auths "returns unauthorized" do
      response = request("/role.all")

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end
  end

  describe "/role.delete" do
    test_with_auths "returns unauthorized" do
      response = request("/role.all")

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end
  end
end
