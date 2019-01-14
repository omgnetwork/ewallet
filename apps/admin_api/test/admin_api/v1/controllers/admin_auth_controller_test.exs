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

defmodule AdminAPI.V1.AdminAuthControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.Web.V1.{AccountSerializer, UserSerializer}
  alias ActivityLogger.System
  alias EWalletDB.{Account, AuthToken, Membership, Repo, Role, User}

  describe "/admin.login" do
    test "responds with a new auth token if the given email and password are valid" do
      response =
        unauthenticated_request("/admin.login", %{email: @user_email, password: @password})

      auth_token = AuthToken |> get_last_inserted() |> Repo.preload([:user, :account])

      expected = %{
        "version" => @expected_version,
        "success" => true,
        "data" => %{
          "object" => "authentication_token",
          "authentication_token" => auth_token.token,
          "user_id" => auth_token.user.id,
          "user" => auth_token.user |> UserSerializer.serialize() |> stringify_keys(),
          "account_id" => auth_token.account.id,
          "account" => auth_token.account |> AccountSerializer.serialize() |> stringify_keys(),
          "master_admin" => true,
          "role" => "admin"
        }
      }

      assert response == expected
    end

    test "responds with a new auth token if credentials are valid but user is not master_admin" do
      user = get_test_admin() |> Repo.preload([:accounts])
      {:ok, _} = Membership.unassign(user, Enum.at(user.accounts, 0), %System{})
      account = insert(:account)
      role = Role.get_by(name: "admin")
      _membership = insert(:membership, %{user: user, role: role, account: account})

      response =
        unauthenticated_request("/admin.login", %{email: @user_email, password: @password})

      auth_token = AuthToken |> get_last_inserted() |> Repo.preload([:user, :account])

      expected = %{
        "version" => @expected_version,
        "success" => true,
        "data" => %{
          "object" => "authentication_token",
          "authentication_token" => auth_token.token,
          "user_id" => auth_token.user.id,
          "user" => auth_token.user |> UserSerializer.serialize() |> stringify_keys(),
          "account_id" => auth_token.account.id,
          "account" => auth_token.account |> AccountSerializer.serialize() |> stringify_keys(),
          "master_admin" => false,
          "role" => "admin"
        }
      }

      assert response == expected
    end

    test "responds with a new auth token if credentials are valid and user is a viewer" do
      user = get_test_admin() |> Repo.preload([:accounts])
      {:ok, _} = Membership.unassign(user, Enum.at(user.accounts, 0), %System{})
      account = insert(:account)
      role = insert(:role, %{name: "viewer"})
      _membership = insert(:membership, %{user: user, role: role, account: account})

      response =
        unauthenticated_request("/admin.login", %{email: @user_email, password: @password})

      auth_token = AuthToken |> get_last_inserted() |> Repo.preload([:user, :account])

      expected = %{
        "version" => @expected_version,
        "success" => true,
        "data" => %{
          "object" => "authentication_token",
          "authentication_token" => auth_token.token,
          "user_id" => auth_token.user.id,
          "user" => auth_token.user |> UserSerializer.serialize() |> stringify_keys(),
          "account_id" => auth_token.account.id,
          "account" => auth_token.account |> AccountSerializer.serialize() |> stringify_keys(),
          "master_admin" => false,
          "role" => "viewer"
        }
      }

      assert response == expected
    end

    test "returns an error if the credentials are valid but the email invite is not yet accepted" do
      {:ok, _user} =
        [email: @user_email]
        |> User.get_by()
        |> User.update(%{
          invite_uuid: insert(:invite).uuid,
          originator: %System{}
        })

      response =
        unauthenticated_request("/admin.login", %{email: @user_email, password: @password})

      assert response["version"] == @expected_version
      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:invite_pending"
      assert response["data"]["description"] == "The user has not accepted the invite."
    end

    test "returns an error if the given email does not exist" do
      response =
        unauthenticated_request("/admin.login", %{
          email: "wrong_email@example.com",
          password: @password
        })

      expected = %{
        "version" => @expected_version,
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "user:invalid_login_credentials",
          "description" => "There is no user corresponding to the provided login credentials.",
          "messages" => nil
        }
      }

      assert response == expected
    end

    test "returns an error if the given password is incorrect" do
      response =
        unauthenticated_request("/admin.login", %{email: @user_email, password: "wrong_password"})

      expected = %{
        "version" => @expected_version,
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "user:invalid_login_credentials",
          "description" => "There is no user corresponding to the provided login credentials.",
          "messages" => nil
        }
      }

      assert response == expected
    end

    test "returns :invalid_parameter if email is blank" do
      response = unauthenticated_request("/admin.login", %{email: "", password: @password})
      refute response["success"]
      assert response["data"]["code"] == "user:invalid_login_credentials"
    end

    test "returns :invalid_parameter if password is blank" do
      response = unauthenticated_request("/admin.login", %{email: @user_email, password: ""})
      refute response["success"]
      assert response["data"]["code"] == "user:invalid_login_credentials"
    end

    test "returns :invalid_parameter if email is missing" do
      response = unauthenticated_request("/admin.login", %{email: nil, password: @password})
      refute response["success"]
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test "returns :invalid_parameter if password is missing" do
      response = unauthenticated_request("/admin.login", %{email: @user_email, password: nil})
      refute response["success"]
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test "returns :invalid_parameter if both email and password are missing" do
      response = unauthenticated_request("/admin.login", %{foo: "bar"})
      refute response["success"]
      refute response["success"]
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test "generates an activity log" do
      timestamp = DateTime.utc_now()

      response =
        unauthenticated_request("/admin.login", %{email: @user_email, password: @password})

      assert response["success"] == true
      auth_token = AuthToken |> get_last_inserted() |> Repo.preload([:user, :account])
      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: get_test_admin(),
        target: auth_token,
        changes: %{
          "account_uuid" => auth_token.account.uuid,
          "owner_app" => "admin_api",
          "token" => auth_token.token,
          "user_uuid" => auth_token.user.uuid
        },
        encrypted_changes: %{}
      )
    end
  end

  describe "/auth_token.switch_account" do
    test "switches the account" do
      user = get_test_admin()
      account = insert(:account, parent: Account.get_master_account())

      # User belongs to the master account and has access to the sub account
      # just created
      response =
        admin_user_request("/auth_token.switch_account", %{
          "account_id" => account.id
        })

      assert response["success"]
      assert response["data"]["user"]["id"] == user.id
      assert response["data"]["account"]["id"] == account.id
    end

    test "returns a permission error when trying to switch to an invalid account" do
      user = get_test_admin() |> Repo.preload([:accounts])
      {:ok, _} = Membership.unassign(user, Enum.at(user.accounts, 0), %System{})
      account = insert(:account)

      response =
        admin_user_request("/auth_token.switch_account", %{
          "account_id" => account.id
        })

      refute response["success"]
      assert response["data"]["code"] == "unauthorized"
    end

    test "returns :unauthorized when the account does not exist" do
      response =
        admin_user_request("/auth_token.switch_account", %{
          "account_id" => "123"
        })

      refute response["success"]
      assert response["data"]["code"] == "unauthorized"
    end

    test "returns :invalid_parameter when account_id is not sent" do
      response =
        admin_user_request("/auth_token.switch_account", %{
          "fake" => "123"
        })

      refute response["success"]
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test "returns :auth_token_not_found if user credentials are invalid" do
      response =
        admin_user_request(
          "/auth_token.switch_account",
          %{
            "account_id" => "123"
          },
          auth_token: "bad_auth_token"
        )

      refute response["success"]
      assert response["data"]["code"] == "auth_token:not_found"
    end

    test "gets access_key:unauthorized back when requesting with a provider key" do
      account = insert(:account)

      # User belongs to the master account and has access to the sub account
      # just created
      response =
        provider_request("/auth_token.switch_account", %{
          "account_id" => account.id
        })

      refute response["success"]
      assert response["data"]["code"] == "access_key:unauthorized"
    end

    test "generates an activity log" do
      account = insert(:account, parent: Account.get_master_account())
      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/auth_token.switch_account", %{
          "account_id" => account.id
        })

      assert response["success"] == true
      auth_token = AuthToken |> get_last_inserted() |> Repo.preload([:user, :account])
      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: get_test_admin(),
        target: auth_token,
        changes: %{
          "account_uuid" => account.uuid
        },
        encrypted_changes: %{}
      )
    end
  end

  describe "/me.logout" do
    test "responds success with empty response when successful" do
      response = admin_user_request("/me.logout")

      expected = %{
        "version" => @expected_version,
        "success" => true,
        "data" => %{}
      }

      assert response == expected
    end

    test "prevents following calls from using the same credentials" do
      response1 = admin_user_request("/me.logout")
      assert response1["success"]

      response2 = admin_user_request("/me.logout")
      refute response2["success"]
      assert response2["data"]["code"] == "user:auth_token_expired"
    end

    test "gets access_key:unauthorized back when requesting with a provider key" do
      response = provider_request("/me.logout")
      refute response["success"]
      assert response["data"]["code"] == "access_key:unauthorized"
    end

    test "generates an activity log" do
      timestamp = DateTime.utc_now()

      response = admin_user_request("/me.logout")

      assert response["success"] == true
      auth_token = AuthToken |> get_last_inserted() |> Repo.preload([:user, :account])
      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: get_test_admin(),
        target: auth_token,
        changes: %{
          "expired" => true
        },
        encrypted_changes: %{}
      )
    end
  end
end
