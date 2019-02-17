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

defmodule EWalletAPI.V1.AuthViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWallet.Web.V1.UserSerializer
  alias EWalletAPI.V1.AuthView
  alias EWalletDB.Helpers.Preloader

  describe "EWalletAPI.V1.AuthView.render/2" do
    test "renders auth_token.json with correct structure" do
      auth_token = insert(:auth_token) |> Preloader.preload(:user)

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "authentication_token",
          authentication_token: auth_token.token,
          user_id: auth_token.user.id,
          user: UserSerializer.serialize(auth_token.user)
        }
      }

      assert AuthView.render("auth_token.json", %{auth_token: auth_token}) == expected
    end

    test "renders empty_response.json with correct structure" do
      expected = %{
        version: @expected_version,
        success: true,
        data: %{}
      }

      assert AuthView.render("empty_response.json") == expected
    end
  end
end
