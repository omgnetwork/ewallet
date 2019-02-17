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

defmodule EWalletAPI.V1.SelfViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWallet.Web.V1.TokenSerializer
  alias EWalletAPI.V1.SelfView

  describe "EWalletAPI.V1.UserView.render/2" do
    test "renders user.json with correct structure" do
      user = build(:user)

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "user",
          id: user.id,
          socket_topic: "user:#{user.id}",
          provider_user_id: user.provider_user_id,
          username: user.username,
          full_name: user.full_name,
          calling_name: user.calling_name,
          email: user.email,
          enabled: user.enabled,
          avatar: %{
            original: nil,
            large: nil,
            small: nil,
            thumb: nil
          },
          metadata: %{
            "first_name" => user.metadata["first_name"],
            "last_name" => user.metadata["last_name"]
          },
          created_at: nil,
          updated_at: nil,
          encrypted_metadata: %{}
        }
      }

      assert SelfView.render("user.json", %{user: user}) == expected
    end

    test "renders settings.json with correct structure" do
      token1 = build(:token)
      token2 = build(:token)

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "setting",
          tokens: [
            TokenSerializer.serialize(token1),
            TokenSerializer.serialize(token2)
          ]
        }
      }

      settings = %{tokens: [token1, token2]}
      assert SelfView.render("settings.json", settings) == expected
    end
  end
end
