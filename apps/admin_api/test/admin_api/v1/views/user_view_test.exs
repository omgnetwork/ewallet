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

defmodule AdminAPI.V1.UserViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.UserView
  alias EWallet.Web.Paginator
  alias EWalletDB.User
  alias Utils.Helpers.DateFormatter

  describe "AdminAPI.V1.UserView.render/2" do
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

      assert UserView.render("user.json", %{user: user}) == expected
    end

    test "renders users.json with correct response structure" do
      {:ok, user1} = :user |> params_for() |> User.insert()
      {:ok, user2} = :user |> params_for() |> User.insert()

      paginator = %Paginator{
        data: [user1, user2],
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
        data: %{
          object: "list",
          data: [
            %{
              object: "user",
              id: user1.id,
              socket_topic: "user:#{user1.id}",
              username: user1.username,
              full_name: user1.full_name,
              calling_name: user1.calling_name,
              provider_user_id: user1.provider_user_id,
              email: user1.email,
              enabled: user1.enabled,
              avatar: %{
                original: nil,
                large: nil,
                small: nil,
                thumb: nil
              },
              metadata: %{
                "first_name" => user1.metadata["first_name"],
                "last_name" => user1.metadata["last_name"]
              },
              encrypted_metadata: %{},
              created_at: DateFormatter.to_iso8601(user1.inserted_at),
              updated_at: DateFormatter.to_iso8601(user1.updated_at)
            },
            %{
              object: "user",
              id: user2.id,
              socket_topic: "user:#{user2.id}",
              username: user2.username,
              full_name: user2.full_name,
              calling_name: user2.calling_name,
              provider_user_id: user2.provider_user_id,
              email: user2.email,
              enabled: user2.enabled,
              avatar: %{
                original: nil,
                large: nil,
                small: nil,
                thumb: nil
              },
              metadata: %{
                "first_name" => user2.metadata["first_name"],
                "last_name" => user2.metadata["last_name"]
              },
              encrypted_metadata: %{},
              created_at: DateFormatter.to_iso8601(user2.inserted_at),
              updated_at: DateFormatter.to_iso8601(user2.updated_at)
            }
          ],
          pagination: %{
            per_page: 10,
            current_page: 1,
            is_first_page: true,
            is_last_page: false
          }
        }
      }

      assert UserView.render("users.json", %{users: paginator}) == expected
    end
  end
end
