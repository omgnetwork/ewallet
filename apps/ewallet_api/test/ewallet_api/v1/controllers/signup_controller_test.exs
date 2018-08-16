defmodule EWalletAPI.V1.SignupControllerTest do
  use EWalletAPI.ConnCase, async: true

  @redirect_url "http://localhost:4000/api/client/user.verify_email?email={email}&token={token}"

  describe "/user.signup" do
    test "returns success with an empty response" do
      response =
        client_request("/user.signup", %{
          email: "test_user_signup@example.com",
          redirect_url: @redirect_url
        })

      assert response["version"] == @expected_version
      assert response["success"] == true
      assert response["data"] == %{}
    end
  end

  describe "verify_email/2" do
    setup do
      invite = insert(:invite)

      user =
        insert(:user, %{
          email: "verify_email@example.com",
          invite_uuid: invite.uuid
        })

      %{
        user: user,
        token: invite.token
      }
    end

    test "returns success with the user object", context do
      response =
        client_request("/user.verify_email", %{
          email: context.user.email,
          token: context.token,
          password: "the_password",
          password_confirmation: "the_password"
        })

      assert response["version"] == @expected_version
      assert response["success"] == true

      assert response["data"]["object"] == "user"
      assert response["data"]["id"] == context.user.id
    end
  end
end
