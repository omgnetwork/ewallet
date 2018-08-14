defmodule EWalletAPI.V1.AuthControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias EWalletDB.Helpers.Crypto
  alias EWalletDB.User

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

    test "returns user:invite_pending error when the user has a pending invite", context do
      _user = User.update_without_password(context.user, %{invite_uuid: insert(:invite).uuid})
      response = client_request("/user.login", context.request_data)

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:invite_pending"
      assert response["data"]["description"] == "The user has not accepted the invite"
    end

    test "returns user:invalid_login_credentials when given an unknown email", context do
      request_data = %{context.request_data | email: "unknown@example.com"}
      response = client_request("/user.login", request_data)

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:invalid_login_credentials"

      assert response["data"]["description"] ==
               "There is no user corresponding to the provided login credentials"
    end

    test "returns user:invalid_login_credentials when given an invalid password", context do
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

      assert response["data"]["description"] ==
               "Invalid parameter provided. `email` can't be blank"
    end

    test "returns client:invalid_parameter when password is not provided", context do
      request_data = %{context.request_data | password: nil}
      response = client_request("/user.login", request_data)

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `password` can't be blank"
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
