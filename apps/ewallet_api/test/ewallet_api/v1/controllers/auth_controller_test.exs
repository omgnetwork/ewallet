defmodule EWalletAPI.V1.AuthControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias EWalletDB.Helpers.Crypto

  describe "/user.signup" do
    test "returns success with the new user object" do
      response =
        client_request("/user.signup", %{
          email: "test_user_signup@example.com",
          password: "some_password",
          password_confirmation: "some_password"
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
          password_confirmation: "different_password"
        })

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] =~ "`password_confirmation` does not match password."
    end

    test "returns client:invalid_parameter when email is not provided" do
      response =
        client_request("/user.signup", %{
          email: nil,
          password: "some_password",
          password_confirmation: "some_password"
        })

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] =~ "Invalid parameter provided. `email` is required"
    end

    test "returns client:invalid_parameter when password is less than 8 characters" do
      response =
        client_request("/user.signup", %{
          email: "test_user_signup@example.com",
          password: "short",
          password_confirmation: "short"
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
          password_confirmation: "some_password"
        })

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] =~ "`password` can't be blank"
    end
  end

  describe "/user.login" do
    setup do
      email = "test_user_login@example.com"
      password = "some_password"
      password_hash = Crypto.hash_password(password)

      user = insert(:user, email: email, password_hash: password_hash)
      request_data = %{email: email, password: password}

      %{
        request_data: request_data,
        user: user
      }
    end

    test "returns success with the user object", context do
      response = client_request("/user.login", context.request_data)

      assert response["version"] == @expected_version
      assert response["success"] == true

      assert response["data"]["object"] == "authentication_token"
      assert response["data"]["authentication_token"] != nil
      assert response["data"]["user_id"] == context.user.id
      assert response["data"]["user"]["id"] == context.user.id
      assert response["data"]["user"]["email"] == context.user.email
    end

    test "returns user:invalid_login_credentials when given unknown email", context do
      request_data = %{context.request_data | email: "unknown@example.com"}
      response = client_request("/user.login", request_data)

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:invalid_login_credentials"
      assert response["data"]["description"] ==
        "There is no user corresponding to the provided login credentials"
    end

    test "returns user:invalid_login_credentials when given invalid password", context do
      request_data = %{context.request_data | password: "wrong_password"}
      response = client_request("/user.login", request_data)

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:invalid_login_credentials"
      assert response["data"]["description"] ==
        "There is no user corresponding to the provided login credentials"
    end

    test "returns client:invalid_parameter when email is not provided", context do
      request_data = %{context.request_data | email: nil}
      response = client_request("/user.login", request_data)

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided. `email` is required"
    end

    test "returns client:invalid_parameter when password is not provided", context do
      request_data = %{context.request_data | password: nil}
      response = client_request("/user.login", request_data)

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided. `password` is required"
    end
  end

  describe "/me.logout" do
    test "responds success with empty response if logout successfully" do
      response = client_request("/me.logout")

      assert response["version"] == @expected_version
      assert response["success"] == true
      assert response["data"] == %{}
    end
  end
end
