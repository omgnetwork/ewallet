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

defmodule AdminAPI.V1.AdminUserControllerTest do
  use AdminAPI.ConnCase, async: true
  alias Ecto.UUID
  alias EWalletDB.{User, Account, AuthToken, Membership}
  alias ActivityLogger.System

  @owner_app :some_app

  describe "/admin.all" do
    test_with_auths "returns a list of admins and pagination data" do
      response = request("/admin.all")

      # Asserts return data
      assert response["success"]
      assert response["data"]["object"] == "list"
      assert is_list(response["data"]["data"])

      # Asserts pagination data
      pagination = response["data"]["pagination"]
      assert is_integer(pagination["per_page"])
      assert is_integer(pagination["current_page"])
      assert is_boolean(pagination["is_last_page"])
      assert is_boolean(pagination["is_first_page"])
    end

    test_with_auths "returns a list of admins according to start_from and start_by" do
      account = insert(:account)

      admin1 = insert(:admin, %{email: "admin1@omise.co"})
      admin2 = insert(:admin, %{email: "admin2@omise.co"})
      admin3 = insert(:admin, %{email: "admin3@omise.co"})
      _user = insert(:user, %{email: "user1@omise.co"})

      {:ok, _} = Membership.assign(admin1, account, "admin", %System{})
      {:ok, _} = Membership.assign(admin2, account, "admin", %System{})
      {:ok, _} = Membership.assign(admin3, account, "admin", %System{})

      attrs = %{
        "start_after" => admin1.id,
        "start_by" => "id"
      }

      response = request("/admin.all", attrs)
      admins = response["data"]["data"]

      assert response["success"]
      assert Enum.count(admins) == 2
      assert Enum.at(admins, 0)["email"] == "admin2@omise.co"
      assert Enum.at(admins, 1)["email"] == "admin3@omise.co"
    end

    test_with_auths "returns a list of admins according to search_term, sort_by and sort_direction" do
      account = insert(:account)

      admin1 = insert(:admin, %{email: "admin1@omise.co"})
      admin2 = insert(:admin, %{email: "admin2@omise.co"})
      admin3 = insert(:admin, %{email: "admin3@omise.co"})
      _user = insert(:user, %{email: "user1@omise.co"})

      {:ok, _} = Membership.assign(admin1, account, "admin", %System{})
      {:ok, _} = Membership.assign(admin2, account, "admin", %System{})
      {:ok, _} = Membership.assign(admin3, account, "admin", %System{})

      attrs = %{
        # Search is case-insensitive
        "search_term" => "AdMiN",
        "sort_by" => "email",
        "sort_dir" => "desc"
      }

      response = request("/admin.all", attrs)
      admins = response["data"]["data"]

      assert response["success"]
      assert Enum.count(admins) == 3
      assert Enum.at(admins, 0)["email"] == "admin3@omise.co"
      assert Enum.at(admins, 1)["email"] == "admin2@omise.co"
      assert Enum.at(admins, 2)["email"] == "admin1@omise.co"
    end

    # This is a variation of `ConnCase.test_supports_match_any/5` that inserts
    # an admin and a membership in order for the inserted admin to appear in the result.
    test_with_auths "supports match_any filtering" do
      account = insert(:account)

      admin_1 = insert(:admin, username: "value_1")
      admin_2 = insert(:admin, username: "value_2")
      admin_3 = insert(:admin, username: "value_3")
      admin_4 = insert(:admin, username: "value_4")

      {:ok, _} = Membership.assign(admin_1, account, "admin", %System{})
      {:ok, _} = Membership.assign(admin_2, account, "admin", %System{})
      {:ok, _} = Membership.assign(admin_3, account, "admin", %System{})
      {:ok, _} = Membership.assign(admin_4, account, "admin", %System{})

      attrs = %{
        "match_any" => [
          %{
            "field" => "username",
            "comparator" => "eq",
            "value" => "value_2"
          },
          %{
            "field" => "username",
            "comparator" => "eq",
            "value" => "value_4"
          }
        ]
      }

      response = request("/admin.all", attrs)

      assert response["success"]

      records = response["data"]["data"]
      assert Enum.count(records) == 2
      assert Enum.any?(records, fn r -> r["id"] == admin_2.id end)
      assert Enum.any?(records, fn r -> r["id"] == admin_4.id end)
    end

    # This is a variation of `ConnCase.test_supports_match_all/5` that inserts
    # an admin and a membership in order for the inserted admin to appear in the result.
    test_with_auths "supports match_all filtering" do
      account = insert(:account)

      admin_1 = insert(:admin, %{username: "this_should_almost_match"})
      admin_2 = insert(:admin, %{username: "this_should_match"})
      admin_3 = insert(:admin, %{username: "should_not_match"})
      admin_4 = insert(:admin, %{username: "also_should_not_match"})

      {:ok, _} = Membership.assign(admin_1, account, "admin", %System{})
      {:ok, _} = Membership.assign(admin_2, account, "admin", %System{})
      {:ok, _} = Membership.assign(admin_3, account, "admin", %System{})
      {:ok, _} = Membership.assign(admin_4, account, "admin", %System{})

      attrs = %{
        "match_all" => [
          %{
            "field" => "username",
            "comparator" => "starts_with",
            "value" => "this_should"
          },
          %{
            "field" => "username",
            "comparator" => "contains",
            "value" => "should_match"
          }
        ]
      }

      response = request("/admin.all", attrs)

      assert response["success"]

      records = response["data"]["data"]
      assert Enum.count(records) == 1
      assert Enum.any?(records, fn r -> r["id"] == admin_2.id end)
    end
  end

  describe "/admin.get" do
    test_with_auths "returns an admin by the given admin's ID" do
      account = insert(:account)
      admin = insert(:admin, %{email: "admin@omise.co"})
      {:ok, _} = Membership.assign(admin, account, "admin", %System{})

      response = request("/admin.get", %{"id" => admin.id})

      assert response["success"]
      assert response["data"]["object"] == "user"
      assert response["data"]["email"] == admin.email
    end

    test_with_auths "returns 'client:invalid_parameter' error when id is not given" do
      response = request("/account.get", %{})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided. `id` is required."
    end

    test_with_auths "returns 'unauthorized' if the given ID is not an admin" do
      {:ok, user} = :user |> params_for() |> User.insert()
      response = request("/admin.get", %{"id" => user.id})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end

    test_with_auths "returns 'unauthorized' if the given ID was not found" do
      response = request("/admin.get", %{"id" => UUID.generate()})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end

    test_with_auths "returns 'unauthorized' if the given ID format is invalid" do
      response = request("/admin.get", %{"id" => "not_valid_id_format"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"

      assert response["data"]["description"] ==
               "You are not allowed to perform the requested operation."
    end
  end

  describe "/user.enable_or_disable" do
    test_with_auths "disable an admin succeed and disable his tokens" do
      account = Account.get_master_account()
      admin = insert(:admin, %{email: "admin@omise.co"})
      {:ok, _} = Membership.assign(admin, account, "admin", %System{})

      {:ok, token} = AuthToken.generate(admin, @owner_app, %System{})
      token_string = token.token
      # Ensure tokens is usable.
      assert AuthToken.authenticate(token_string, @owner_app)

      response =
        request("/admin.enable_or_disable", %{
          id: admin.id,
          enabled: false
        })

      assert response["success"] == true
      assert response["data"]["enabled"] == false
      assert AuthToken.authenticate(token_string, @owner_app) == :token_expired
    end

    test_with_auths "disable an admin that doesn't exist raises an 'unauthorized' error" do
      response =
        request("/admin.enable_or_disable", %{
          id: "invalid_id",
          enabled: false
        })

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end

    test_with_auths "disable an admin with missing params raises an error" do
      response =
        request("/admin.enable_or_disable", %{
          enabled: false
        })

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided. `id` is required."
    end

    test "disable myself with an admin request raises an authorization error" do
      response =
        admin_user_request("/admin.enable_or_disable", %{
          id: @admin_id,
          enabled: false
        })

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"

      assert response["data"]["description"] ==
               "You are not allowed to perform the requested operation."
    end

    defp assert_enable_logs(logs, originator, target) do
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: originator,
        target: target,
        changes: %{
          "enabled" => target.enabled
        },
        encrypted_changes: %{}
      )
    end

    test "generates an activity log for an admin request" do
      account = Account.get_master_account()
      admin = insert(:admin, %{email: "admin@omise.co"})
      {:ok, _} = Membership.assign(admin, account, "admin", %System{})

      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/admin.enable_or_disable", %{
          id: admin.id,
          enabled: false
        })

      assert response["success"] == true
      admin = User.get(admin.id)

      timestamp
      |> get_all_activity_logs_since()
      |> assert_enable_logs(get_test_admin(), admin)
    end

    test "generates an activity log for a provider request" do
      account = Account.get_master_account()
      admin = insert(:admin, %{email: "admin@omise.co"})
      {:ok, _} = Membership.assign(admin, account, "admin", %System{})

      timestamp = DateTime.utc_now()

      response =
        provider_request("/admin.enable_or_disable", %{
          id: admin.id,
          enabled: false
        })

      assert response["success"] == true
      admin = User.get(admin.id)

      timestamp
      |> get_all_activity_logs_since()
      |> assert_enable_logs(get_test_key(), admin)
    end
  end
end
