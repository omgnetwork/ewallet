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

defmodule AdminAPI.V1.PermissionViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.PermissionnView
  alias EWallet.Web.V1.PermissionSerializer
  alias EWalletDB.{GlobalRole, Role}

  describe "render/2" do
    test "renders permissions.json with V1 response structure" do
      permissions = %{
        global_roles: GlobalRole.global_role_permissions(),
        account_roles: Role.account_role_permissions()
      }

      response = PermissionView.render("permissions.json", permissions)

      # Assert that the data went through the ResponseSerializer
      assert response["success"] == true
      assert Map.has_key?(response, "version")
      assert Map.has_key?(response, "data")

      # Assert that the data went through the PermissionSerializer
      assert response["data"]["object"] == "permissions"
      assert Map.has_key?(response["data"], "global_roles")
      assert Map.has_key?(response["data"], "account_roles")
    end
  end
end
