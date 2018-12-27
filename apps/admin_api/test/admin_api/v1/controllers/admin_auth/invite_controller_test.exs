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

defmodule AdminAPI.V1.AdminAuth.InviteControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.Web.Date
  alias EWalletDB.{Invite, User, Repo}
  alias ActivityLogger.System

  defp request(email, token, password, password_confirmation) do
    unauthenticated_request("/invite.accept", %{
      "email" => email,
      "token" => token,
      "password" => password,
      "password_confirmation" => password_confirmation
    })
  end

  describe "InviteController.accept/2" do
    test "returns success if invite is accepted successfully" do
      {:ok, user} = :admin |> params_for(is_admin: false) |> User.insert()
      {:ok, invite} = Invite.generate(user, %System{}, preload: :user)

      response = request(invite.user.email, invite.token, "some_password", "some_password")

      expected = %{
        "object" => "user",
        "id" => invite.user.id,
        "socket_topic" => "user:#{user.id}",
        "provider_user_id" => nil,
        "username" => nil,
        "full_name" => nil,
        "calling_name" => nil,
        "email" => invite.user.email,
        "avatar" => %{"original" => nil, "large" => nil, "small" => nil, "thumb" => nil},
        "enabled" => invite.user.enabled,
        "metadata" => %{
          "first_name" => invite.user.metadata["first_name"],
          "last_name" => invite.user.metadata["last_name"]
        },
        "encrypted_metadata" => %{},
        "created_at" => Date.to_iso8601(invite.user.inserted_at),
        "updated_at" => Date.to_iso8601(invite.user.updated_at)
      }

      assert response["success"]
      assert response["data"] == expected

      # The user should be an admin after the invite is successfully accepted
      assert invite.user.id |> User.get() |> User.admin?()
    end

    test "generates activity logs" do
      {:ok, user} = :admin |> params_for(is_admin: false) |> User.insert()
      {:ok, invite} = Invite.generate(user, %System{}, preload: :user)
      timestamp = DateTime.utc_now()

      response = request(invite.user.email, invite.token, "some_password", "some_password")
      assert response["success"] == true

      invite = Repo.get_by(Invite, uuid: invite.uuid)
      user = User.get(user.id)

      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 4

      # Update user password
      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: user,
        target: user,
        changes: %{"password_hash" => user.password_hash},
        encrypted_changes: %{}
      )

      # Update invite_uuid to nil
      logs
      |> Enum.at(1)
      |> assert_activity_log(
        action: "update",
        originator: user,
        target: user,
        changes: %{"invite_uuid" => nil},
        encrypted_changes: %{}
      )

      # Update verified_at for the invitation
      logs
      |> Enum.at(2)
      |> assert_activity_log(
        action: "update",
        originator: user,
        target: invite,
        changes: %{"verified_at" => NaiveDateTime.to_iso8601(invite.verified_at)},
        encrypted_changes: %{}
      )

      # Set is admin
      logs
      |> Enum.at(3)
      |> assert_activity_log(
        action: "update",
        originator: :system,
        target: user,
        changes: %{"is_admin" => true},
        encrypted_changes: %{}
      )

      Enum.each(logs, fn log ->
        assert log.target_changes["password"] == nil
        assert log.target_encrypted_changes["password"] == nil
      end)
    end

    test "returns :invite_not_found error if the email has not been invited" do
      {:ok, user} = :admin |> params_for() |> User.insert()
      {:ok, invite} = Invite.generate(user, %System{})

      response = request("unknown@example.com", invite.token, "some_password", "some_password")

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:invite_not_found"

      assert response["data"]["description"] ==
               "There is no invite corresponding to the provided email and token."
    end

    test "returns :invite_not_found error if the token is incorrect" do
      {:ok, user} = :admin |> params_for() |> User.insert()
      {:ok, _invite} = Invite.generate(user, %System{})

      response = request(user.email, "wrong_token", "some_password", "some_password")

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:invite_not_found"

      assert response["data"]["description"] ==
               "There is no invite corresponding to the provided email and token."
    end

    test "returns client:invalid_parameter error if the password has less than 8 characters" do
      {:ok, user} = :admin |> params_for() |> User.insert()
      {:ok, invite} = Invite.generate(user, %System{})

      response = request(user.email, invite.token, "short", "short")

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `password` must be 8 characters or more."
    end

    test "returns :invalid_parameter error if a required parameter is missing" do
      {:ok, user} = :admin |> params_for() |> User.insert()
      {:ok, invite} = Invite.generate(user, %System{})

      # Missing passwords
      response =
        unauthenticated_request("/invite.accept", %{
          "email" => user.email,
          "token" => invite.token
        })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `email`, `token`, `password`, `password_confirmation` are required."
    end
  end
end
