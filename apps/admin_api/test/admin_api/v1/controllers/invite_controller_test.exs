defmodule AdminAPI.V1.InviteControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.Web.Date

  defp request(email, token, password, password_confirmation) do
    client_request("/invite.accept", %{
      "email" => email,
      "token" => token,
      "password" => password,
      "password_confirmation" => password_confirmation
    })
  end

  describe "InviteController.accept/2" do
    test "returns success if invite is accepted successfully" do
      invite = insert(:invite)
      user = insert(:admin, %{invite: invite})
      response = request(user.email, invite.token, "some_password", "some_password")

      expected = %{
        "object" => "user",
        "id" => user.id,
        "socket_topic" => "user:#{user.id}",
        "provider_user_id" => nil,
        "username" => nil,
        "email" => user.email,
        "avatar" => %{"original" => nil, "large" => nil, "small" => nil, "thumb" => nil},
        "metadata" => %{
          "first_name" => user.metadata["first_name"],
          "last_name" => user.metadata["last_name"]
        },
        "encrypted_metadata" => %{},
        "created_at" => Date.to_iso8601(user.inserted_at),
        "updated_at" => Date.to_iso8601(user.updated_at)
      }

      assert response["success"]
      assert response["data"] == expected
    end

    test "returns :invite_not_found error if the email has not been invited" do
      invite = insert(:invite)
      _user = insert(:admin, %{invite: invite})
      response = request("unknown@example.com", invite.token, "some_password", "some_password")

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:invite_not_found"

      assert response["data"]["description"] ==
               "There is no invite corresponding to the provided email and token"
    end

    test "returns :invite_not_found error if the token is incorrect" do
      invite = insert(:invite)
      user = insert(:admin, %{invite: invite})
      response = request(user.email, "wrong_token", "some_password", "some_password")

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:invite_not_found"

      assert response["data"]["description"] ==
               "There is no invite corresponding to the provided email and token"
    end

    test "returns :passwords_mismatch error if the passwords do not match" do
      invite = insert(:invite)
      user = insert(:admin, %{invite: invite})
      response = request(user.email, invite.token, "some_password", "mismatch_password")

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:passwords_mismatch"
      assert response["data"]["description"] == "The provided passwords do not match"
    end

    test "returns :invalid_parameter error if a required parameter is missing" do
      invite = insert(:invite)
      user = insert(:admin, %{invite: invite})

      # Missing passwords
      response =
        client_request("/invite.accept", %{"email" => user.email, "token" => invite.token})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided"
    end
  end
end
