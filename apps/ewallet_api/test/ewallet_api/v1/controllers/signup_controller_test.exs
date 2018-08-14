defmodule EWalletAPI.V1.SignupControllerTest do
  use EWalletAPI.ConnCase, async: true

  @redirect_url "http://localhost:4000/user.verify_email?email={email}&token={token}"

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
          password: "some_password",
          password_confirmation: "some_password",
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
          password: "some_password",
          password_confirmation: "some_password",
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
          password: "some_password",
          password_confirmation: "some_password",
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
end
