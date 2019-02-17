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

defmodule AdminAPI.V1.UserAuthViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.UserAuthView
  alias EWallet.Web.V1.UserAuthTokenSerializer

  describe "render/2" do
    test "renders auth_token.json with the given mint" do
      auth_token = insert(:auth_token)

      expected = %{
        version: @expected_version,
        success: true,
        data: UserAuthTokenSerializer.serialize(auth_token)
      }

      assert UserAuthView.render("auth_token.json", %{auth_token: auth_token}) == expected
    end

    test "renders empty_response.json" do
      expected = %{
        version: @expected_version,
        success: true,
        data: %{}
      }

      assert UserAuthView.render("empty_response.json", %{success: true}) == expected
    end
  end
end
