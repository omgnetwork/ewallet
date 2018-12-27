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

defmodule EWalletAPI.V1.SignupViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWallet.Web.V1.UserSerializer
  alias EWalletAPI.V1.SignupView

  describe "render/2" do
    test "renders empty.json correctly" do
      assert SignupView.render("empty.json", %{success: true}) ==
               %{
                 version: @expected_version,
                 success: true,
                 data: %{}
               }
    end

    test "renders user.json with the correct structure" do
      user = insert(:user)

      expected = %{
        version: @expected_version,
        success: true,
        data: UserSerializer.serialize(user)
      }

      assert SignupView.render("user.json", %{user: user}) == expected
    end
  end
end
