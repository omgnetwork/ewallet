defmodule EWalletAPI.V1.SignupControllerTest do
  use EWalletAPI.ConnCase, async: true

  @redirect_url "http://localhost:4000/invite?email={email}&token={token}"

  describe "/user.signup" do
    test "returns success with the new user object" do
      response =
        client_request("/user.signup", %{
          email: "test_user_signup@example.com",
          password: "some_password",
          password_confirmation: "some_password",
          redirect_url: @redirect_url
        })

      assert response["version"] == @expected_version
      assert response["success"] == true

      assert response["data"]["object"] == "user"
      assert response["data"]["email"] == "test_user_signup@example.com"
    end

    test "returns user:passwords_mismatch when the provided passwords do not match" do
      response =
        client_request("/user.signup", %{
          email: "test_user_signup@example.com",
          password: "some_password",
          password_confirmation: "different_password",
          redirect_url: @redirect_url
        })

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:passwords_mismatch"
      assert response["data"]["description"] == "The provided passwords do not match"
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

    test "returns client:invalid_parameter when password is less than 8 characters" do
      response =
        client_request("/user.signup", %{
          email: "test_user_signup@example.com",
          password: "short",
          password_confirmation: "short",
          redirect_url: @redirect_url
        })

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] =~ "`password` must be 8 characters or more"
    end

    test "returns client:invalid_parameter when password is not provided" do
      response =
        client_request("/user.signup", %{
          email: "test_user_signup@example.com",
          password: nil,
          password_confirmation: nil,
          redirect_url: @redirect_url
        })

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] =~ "`password` can't be blank"
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
