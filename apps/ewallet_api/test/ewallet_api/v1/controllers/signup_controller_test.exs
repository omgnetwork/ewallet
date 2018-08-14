defmodule EWalletAPI.V1.SignupControllerTest do
  use EWalletAPI.ConnCase, async: true

  @redirect_url "http://localhost:4000/api/client/user.verify_email?email={email}&token={token}"

  describe "/user.signup" do
    test "returns success with the new user object" do
      response =
        client_request("/user.signup", %{
          email: "test_user_signup@example.com",
          redirect_url: @redirect_url
        })

      assert response["version"] == @expected_version
      assert response["success"] == true

      assert response["data"]["object"] == "user"
      assert response["data"]["email"] == "test_user_signup@example.com"
    end

    test "returns client:invalid_parameter when email is not provided" do
      response =
        client_request("/user.signup", %{
          email: nil,
          redirect_url: @redirect_url
        })

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] =~
               "Invalid parameter provided. `email` can't be blank"
    end

    test "returns user:already_active when a user with the provided email already exists" do
      _ = insert(:user, email: "already_exists@example.com")

      response =
        client_request("/user.signup", %{
          email: "already_exists@example.com",
          redirect_url: @redirect_url
        })

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:already_active"
      assert response["data"]["description"] == "The user already exists and active"
    end

    test "returns client:invalid_parameter when redirect_url is not provided" do
      response =
        client_request("/user.signup", %{
          email: "test_user_signup@example.com",
          redirect_url: nil
        })

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] =~
               "Invalid parameter provided. `redirect_url` can't be blank"
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

    test "returns the user if verification is sucessful", context do
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

    test "returns user:token_not_found if the token is incorrect", context do
      response =
        client_request("/user.verify_email", %{
          email: context.user.email,
          token: "wrong_token",
          password: "the_password",
          password_confirmation: "the_password"
        })

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:email_token_not_found"

      assert response["data"]["description"] ==
               "There is no pending email verification for the provided email and token"
    end

    test "returns client:passwords_mismatch error if the passwords do not match", context do
      response =
        client_request("/user.verify_email", %{
          email: context.user.email,
          token: context.token,
          password: "different_password",
          password_confirmation: "another_different_password"
        })

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:passwords_mismatch"
      assert response["data"]["description"] == "The provided passwords do not match"
    end

    test "returns client:invalid_parameter error if the password has less than 8 characters",
         context do
      response =
        client_request("/user.verify_email", %{
          email: context.user.email,
          token: context.token,
          password: "short",
          password_confirmation: "short"
        })

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided `password` must be 8 characters or more."
    end

    test "returns client:invalid_parameter error if the password is not provided", context do
      response =
        client_request("/user.verify_email", %{
          email: context.user.email,
          token: context.token
        })

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `password` can't be blank"
    end
  end
end
