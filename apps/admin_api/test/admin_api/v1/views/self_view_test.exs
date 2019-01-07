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

defmodule AdminAPI.V1.SelfViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.SelfView
  alias Utils.Helpers.DateFormatter
  alias EWalletDB.User

  describe "render/2" do
    test "renders user.json with correct response structure" do
      {:ok, user} = :user |> params_for() |> User.insert()

      # I prefer to keep this test code duplicate with the `UserView.render/2` test,
      # because in practice they are separate responses.

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "user",
          id: user.id,
          socket_topic: "user:#{user.id}",
          username: user.username,
          full_name: user.full_name,
          calling_name: user.calling_name,
          provider_user_id: user.provider_user_id,
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
          encrypted_metadata: %{},
          created_at: DateFormatter.to_iso8601(user.inserted_at),
          updated_at: DateFormatter.to_iso8601(user.updated_at)
        }
      }

      assert SelfView.render("user.json", %{user: user}) == expected
    end
  end
end
