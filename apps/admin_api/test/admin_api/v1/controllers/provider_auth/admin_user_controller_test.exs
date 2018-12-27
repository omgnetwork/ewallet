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

defmodule AdminAPI.V1.ProviderAuth.AdminControllerTest do
  use AdminAPI.ConnCase, async: true
  alias Ecto.UUID
  alias EWalletDB.{User, Account, AuthToken}
  alias ActivityLogger.System

  @owner_app :some_app

  describe "/admin.all" do
    test "returns a list of admins and pagination data" do
      response = provider_request("/admin.all")

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

    test "returns a list of admins according to search_term, sort_by and sort_direction" do
      account = insert(:account)
      role = insert(:role, %{name: "some_role"})
      admin1 = insert(:admin, %{email: "admin1@omise.co"})
      admin2 = insert(:admin, %{email: "admin2@omise.co"})
      admin3 = insert(:admin, %{email: "admin3@omise.co"})
      _user = insert(:user, %{email: "user1@omise.co"})

      insert(:membership, %{user: admin1, account: account, role: role})
      insert(:membership, %{user: admin2, account: account, role: role})
      insert(:membership, %{user: admin3, account: account, role: role})

      attrs = %{
        # Search is case-insensitive
        "search_term" => "AdMiN",
        "sort_by" => "email",
        "sort_dir" => "desc"
      }

      response = provider_request("/admin.all", attrs)
      admins = response["data"]["data"]

      assert response["success"]
      assert Enum.count(admins) == 3
      assert Enum.at(admins, 0)["email"] == "admin3@omise.co"
      assert Enum.at(admins, 1)["email"] == "admin2@omise.co"
      assert Enum.at(admins, 2)["email"] == "admin1@omise.co"
    end

    # This is a variation of `ConnCase.test_supports_match_any/5` that inserts
    # an admin and a membership in order for the inserted admin to appear in the result.
    test "supports match_any filtering" do
      admin_1 = insert(:admin, username: "value_1")
      admin_2 = insert(:admin, username: "value_2")
      admin_3 = insert(:admin, username: "value_3")
      admin_4 = insert(:admin, username: "value_4")

      _ = insert(:membership, %{user: admin_1})
      _ = insert(:membership, %{user: admin_2})
      _ = insert(:membership, %{user: admin_3})
      _ = insert(:membership, %{user: admin_4})

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

      response = provider_request("/admin.all", attrs)

      assert response["success"]

      records = response["data"]["data"]
      assert Enum.any?(records, fn r -> r["id"] == admin_2.id end)
      assert Enum.any?(records, fn r -> r["id"] == admin_4.id end)
      assert Enum.count(records) == 2
    end

    # This is a variation of `ConnCase.test_supports_match_all/5` that inserts
    # an admin and a membership in order for the inserted admin to appear in the result.
    test "supports match_all filtering" do
      account = Account.get_master_account()
      admin_1 = insert(:admin, %{username: "this_should_almost_match"})
      admin_2 = insert(:admin, %{username: "this_should_match"})
      admin_3 = insert(:admin, %{username: "should_not_match"})
      admin_4 = insert(:admin, %{username: "also_should_not_match"})

      _ = insert(:membership, %{user: admin_1, account: account})
      _ = insert(:membership, %{user: admin_2, account: account})
      _ = insert(:membership, %{user: admin_3, account: account})
      _ = insert(:membership, %{user: admin_4, account: account})

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

      response = provider_request("/admin.all", attrs)

      assert response["success"]

      records = response["data"]["data"]
      assert Enum.any?(records, fn r -> r["id"] == admin_2.id end)
      assert Enum.count(records) == 1
    end
  end

  describe "/admin.get" do
    test "returns an admin by the given admin's ID" do
      account = insert(:account)
      role = insert(:role, %{name: "some_role"})
      admin = insert(:admin, %{email: "admin@omise.co"})
      _membership = insert(:membership, %{user: admin, account: account, role: role})

      response = provider_request("/admin.get", %{"id" => admin.id})

      assert response["success"]
      assert response["data"]["object"] == "user"
      assert response["data"]["email"] == admin.email
    end

    test "returns 'unauthorized' if the given ID is not an admin" do
      {:ok, user} = :user |> params_for() |> User.insert()
      response = provider_request("/admin.get", %{"id" => user.id})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end

    test "returns 'unauthorized' if the given ID was not found" do
      response = provider_request("/admin.get", %{"id" => UUID.generate()})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end

    test "returns 'unauthorized' if the given ID format is invalid" do
      response = provider_request("/admin.get", %{"id" => "not_valid_id_format"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end
  end

  describe "/user.enable_or_disable" do
    test "disable an admin succeed and disable his tokens" do
      account = Account.get_master_account()
      role = insert(:role, %{name: "some_role"})
      admin = insert(:admin, %{email: "admin@omise.co"})
      _membership = insert(:membership, %{user: admin, account: account, role: role})

      {:ok, token} = AuthToken.generate(admin, @owner_app, %System{})
      token_string = token.token
      # Ensure tokens is usable.
      assert AuthToken.authenticate(token_string, @owner_app)

      response =
        provider_request("/admin.enable_or_disable", %{
          id: admin.id,
          enabled: false
        })

      assert response["success"] == true
      assert response["data"]["enabled"] == false
      assert AuthToken.authenticate(token_string, @owner_app) == :token_expired
    end

    test "can't disable an admin in an account above the current one" do
      master = Account.get_master_account()

      admin = get_test_admin()

      sub_acc = insert(:account, parent: master, name: "Account 1")
      key = insert(:key, %{account: sub_acc})

      response =
        provider_request(
          "/user.enable_or_disable",
          %{
            id: admin.id,
            enabled: false
          },
          access_key: key.access_key,
          secret_key: key.secret_key
        )

      assert response["success"] == false
      assert response["data"]["code"] == "unauthorized"
    end

    test "disable an admin that doesn't exist raises an error" do
      response =
        provider_request("/admin.enable_or_disable", %{
          id: "invalid_id",
          enabled: false
        })

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:id_not_found"

      assert response["data"]["description"] ==
               "There is no user corresponding to the provided id."
    end

    test "disable an admin with missing params raises an error" do
      response =
        provider_request("/admin.enable_or_disable", %{
          enabled: false
        })

      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided. `id` is required."
    end

    test "generates an activity log" do
      account = Account.get_master_account()
      role = insert(:role, %{name: "some_role"})
      admin = insert(:admin, %{email: "admin@omise.co"})
      _membership = insert(:membership, %{user: admin, account: account, role: role})

      timestamp = DateTime.utc_now()

      response =
        provider_request("/admin.enable_or_disable", %{
          id: admin.id,
          enabled: false
        })

      assert response["success"] == true
      admin = User.get(admin.id)
      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: get_test_key(),
        target: admin,
        changes: %{
          "enabled" => false
        },
        encrypted_changes: %{}
      )
    end
  end
end
