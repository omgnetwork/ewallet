defmodule AdminAPI.V1.AdminAuth.InviteControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.Web.Date
  alias EWalletDB.{Invite, User}
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

      response = request(invite.user.email, invite.token, "some_password", "some_password")

      assert response["success"] == true

      user = User.get(response["data"]["id"])
      logs = get_all_activity_logs(user)

      # Set is admin
      log = Enum.at(logs, 0)
      assert log.action == "update"
      assert log.inserted_at != nil
      assert log.originator_type == "system"
      assert log.originator_uuid == "00000000-0000-0000-0000-000000000000"
      assert log.target_type == "user"
      assert log.target_uuid == user.uuid
      assert log.target_changes == %{"is_admin" => true}
      assert log.target_encrypted_changes == %{}

      # update invite_uuid to nil
      log = Enum.at(logs, 1)
      assert log.action == "update"
      assert log.inserted_at != nil
      assert log.originator_type == "user"
      assert log.originator_uuid == user.uuid
      assert log.target_type == "user"
      assert log.target_uuid == user.uuid
      assert log.target_changes == %{"invite_uuid" => nil}
      assert log.target_encrypted_changes == %{}

      # Update user password
      log = Enum.at(logs, 2)
      assert log.action == "update"
      assert log.inserted_at != nil
      assert log.originator_type == "user"
      assert log.originator_uuid == user.uuid
      assert log.target_type == "user"
      assert log.target_uuid == user.uuid
      assert log.target_changes == %{"password_hash" => user.password_hash}
      assert log.target_encrypted_changes == %{}

      # Invite update
      log = Enum.at(logs, 3)
      assert log.action == "update"
      assert log.inserted_at != nil
      assert log.originator_type == "invite"
      assert log.originator_uuid == invite.uuid
      assert log.target_type == "user"
      assert log.target_uuid == user.uuid
      assert log.target_changes == %{"invite_uuid" => invite.uuid}
      assert log.target_encrypted_changes == %{}

      # Set password
      log = Enum.at(logs, 4)
      assert log.action == "insert"
      assert log.inserted_at != nil
      assert log.originator_type == "system"
      assert log.originator_uuid == "00000000-0000-0000-0000-000000000000"
      assert log.target_type == "user"
      assert log.target_uuid == user.uuid
      assert log.target_changes["email"] == user.email
      assert log.target_changes["metadata"] == user.metadata
      assert log.target_changes["password_hash"] != user.password_hash
      assert log.target_encrypted_changes == %{}

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
