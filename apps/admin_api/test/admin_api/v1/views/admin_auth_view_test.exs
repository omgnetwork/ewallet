# Copyright 2019 OmiseGO Pte Ltd
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

defmodule AdminAPI.V1.AdminAuthViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.{AdminAuthView, AuthTokenSerializer}

  describe "AdminAPI.V1.AuthView.render/2" do
    # Potential candidate to be moved to a shared library

    test "renders auth_token.json with correct structure" do
      auth_token = insert(:auth_token)

      expected = %{
        version: @expected_version,
        success: true,
        data: AuthTokenSerializer.serialize(auth_token)
      }

      attrs = %{auth_token: auth_token}
      assert AdminAuthView.render("auth_token.json", attrs) == expected
    end

    test "renders empty_response.json with correct structure" do
      expected = %{
        version: @expected_version,
        success: true,
        data: %{}
      }

      assert AdminAuthView.render("empty_response.json") == expected
    end
  end
end
