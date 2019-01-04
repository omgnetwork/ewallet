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

defmodule AdminAPI.V1.ProviderAuth.UserAuthControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWalletDB.{AuthToken, User}
  alias ActivityLogger.System

  describe "/user.login" do
    test "responds with a new auth token if id is valid" do
      {:ok, user} = :user |> params_for() |> User.insert()
      response = provider_request("/user.login", %{id: user.id})
      auth_token = get_last_inserted(AuthToken)

      assert response["version"] == @expected_version
      assert response["success"] == true

      assert response["data"]["object"] == "authentication_token"
      assert response["data"]["authentication_token"] == auth_token.token
      assert response["data"]["user_id"] == user.id
      assert response["data"]["user"]["id"] == user.id
    end

    test "responds with a new auth token if provider_user_id is valid" do
      user = insert(:user, %{provider_user_id: "1234"})
      response = provider_request("/user.login", %{provider_user_id: "1234"})
      auth_token = get_last_inserted(AuthToken)

      assert response["data"]["object"] == "authentication_token"
      assert response["data"]["authentication_token"] == auth_token.token
      assert response["data"]["user_id"] == user.id
      assert response["data"]["user"]["provider_user_id"] == user.provider_user_id
    end

    test "returns an error if provider_user_id does not match a user" do
      response = provider_request("/user.login", %{provider_user_id: "not_a_user"})

      expected = %{
        "version" => @expected_version,
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "user:provider_user_id_not_found",
          "description" => "There is no user corresponding to the provided provider_user_id.",
          "messages" => nil
        }
      }

      assert response == expected
    end

    test "returns :invalid_parameter if provider_user_id is nil" do
      response = provider_request("/user.login", %{provider_user_id: nil})

      expected = %{
        "version" => @expected_version,
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "user:provider_user_id_not_found",
          "description" => "There is no user corresponding to the provided provider_user_id.",
          "messages" => nil
        }
      }

      assert response == expected
    end

    test "returns :invalid_parameter if provider_user_id is not provided" do
      response = provider_request("/user.login", %{wrong_attr: "user1234"})

      expected = %{
        "version" => @expected_version,
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "client:invalid_parameter",
          "description" => "Invalid parameter provided. `id` or `provider_user_id` is required.",
          "messages" => nil
        }
      }

      assert response == expected
    end

    test "returns user:disabled if the user is disabled" do
      user = insert(:user, %{enabled: false, originator: %System{}})
      response = provider_request("/user.login", %{id: user.id})

      expected = %{
        "version" => @expected_version,
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "user:disabled",
          "description" => "This user is disabled.",
          "messages" => nil
        }
      }

      assert response == expected
    end

    test "generates activity logs" do
      {:ok, user} = :user |> params_for() |> User.insert()
      timestamp = DateTime.utc_now()

      response = provider_request("/user.login", %{id: user.id})

      assert response["success"] == true

      auth_token = get_last_inserted(AuthToken)
      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: get_test_key(),
        target: auth_token,
        changes: %{
          "owner_app" => "ewallet_api",
          "token" => auth_token.token,
          "user_uuid" => user.uuid
        },
        encrypted_changes: %{}
      )
    end
  end

  describe "/user.logout" do
    test "responds success with empty response if logout successfully" do
      _user = insert(:user, %{provider_user_id: "1234"})
      provider_request("/user.login", %{provider_user_id: "1234"})
      auth_token = get_last_inserted(AuthToken)

      response =
        provider_request("/user.logout", %{
          "auth_token" => auth_token.token
        })

      assert response["version"] == @expected_version
      assert response["success"] == true
      assert response["data"] == %{}
    end

    test "generates activity logs" do
      _user = insert(:user, %{provider_user_id: "1234"})
      admin_user_request("/user.login", %{provider_user_id: "1234"})
      auth_token = get_last_inserted(AuthToken)

      timestamp = DateTime.utc_now()

      response =
        provider_request("/user.logout", %{
          "auth_token" => auth_token.token
        })

      assert response["success"] == true

      auth_token = get_last_inserted(AuthToken)
      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: get_test_key(),
        target: auth_token,
        changes: %{
          "expired" => true
        },
        encrypted_changes: %{}
      )
    end
  end
end
