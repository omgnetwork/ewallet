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

defmodule AdminAPI.V1.RoleViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.RoleView
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.RoleSerializer

  describe "render/2" do
    test "renders role.json with correct response structure" do
      role = insert(:role)

      expected = %{
        version: @expected_version,
        success: true,
        data: RoleSerializer.serialize(role)
      }

      assert RoleView.render("role.json", %{role: role}) == expected
    end

    test "renders roles.json with correct response structure" do
      role_1 = insert(:role, name: "role_1")
      role_2 = insert(:role, name: "role_2")

      paginator = %Paginator{
        data: [role_1, role_2],
        pagination: %{
          per_page: 10,
          current_page: 1,
          is_first_page: true,
          is_last_page: false
        }
      }

      expected = %{
        version: @expected_version,
        success: true,
        data: RoleSerializer.serialize(paginator)
      }

      assert RoleView.render("roles.json", %{roles: paginator}) == expected
    end
  end
end
