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

defmodule EWalletAPI.V1.AuthControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias Utils.Helpers.Crypto
  alias EWalletDB.{User, AuthToken}

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

    test "returns user:email_not_verified error when the user has a pending invite", context do
      _user =
        User.update(context.user, %{
          invite_uuid: insert(:invite).uuid,
          originator: :self
        })

      response = client_request("/user.login", context.request_data)

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:email_not_verified"

      assert response["data"]["description"] ==
               "Your user account has not been confirmed yet. Please check your emails."
    end

    test "returns user:invalid_login_credentials when given an unknown email", context do
      request_data = %{context.request_data | email: "unknown@example.com"}
      response = client_request("/user.login", request_data)

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:invalid_login_credentials"

      assert response["data"]["description"] ==
               "There is no user corresponding to the provided login credentials."
    end

    test "returns user:invalid_login_credentials when given an invalid password", context do
      request_data = %{context.request_data | password: "wrong_password"}
      response = client_request("/user.login", request_data)

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:invalid_login_credentials"

      assert response["data"]["description"] ==
               "There is no user corresponding to the provided login credentials."
    end

    test "returns client:invalid_parameter when email is not provided", context do
      request_data = %{context.request_data | email: nil}
      response = client_request("/user.login", request_data)

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `email` can't be blank."
    end

    test "returns client:invalid_parameter when password is not provided", context do
      request_data = %{context.request_data | password: nil}
      response = client_request("/user.login", request_data)

      assert response["version"] == @expected_version
      assert response["success"] == false

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "Invalid parameter provided. `password` can't be blank."
    end

    test "generates an activity log", context do
      timestamp = DateTime.utc_now()

      response = client_request("/user.login", context.request_data)

      assert response["success"] == true
      auth_token = get_last_inserted(AuthToken)

      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: context.user,
        target: auth_token,
        changes: %{
          "owner_app" => "ewallet_api",
          "token" => auth_token.token,
          "user_uuid" => context.user.uuid
        },
        encrypted_changes: %{}
      )
    end
  end

  describe "/me.logout" do
    test "responds success with empty response if logout successfully" do
      response = client_request("/me.logout")

      assert response["version"] == @expected_version
      assert response["success"] == true
      assert response["data"] == %{}
    end

    test "generates an activity log" do
      timestamp = DateTime.utc_now()

      response = client_request("/me.logout")

      assert response["success"] == true
      user = get_test_user()
      auth_token = get_last_inserted(AuthToken)

      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: user,
        target: auth_token,
        changes: %{
          "expired" => true
        },
        encrypted_changes: %{}
      )
    end
  end
end
