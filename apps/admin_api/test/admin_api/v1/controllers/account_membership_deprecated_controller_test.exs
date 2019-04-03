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

defmodule AdminAPI.V1.AccountMembershipDeprecatedControllerTest do
  use AdminAPI.ConnCase, async: true
  alias Utils.Helpers.DateFormatter
  alias EWalletDB.{Role, User, Membership}
  alias ActivityLogger.System

  describe "/account.get_members" do
    test_with_auths "returns a list of users with role and status" do
      account = insert(:account)

      {:ok, user_1} = :user |> params_for() |> User.insert()
      {:ok, user_2} = :user |> params_for() |> User.insert()

      admin_role = Role.get_by(name: "admin")
      viewer_role = insert(:role, name: "viewer")

      {:ok, _} = Membership.assign(user_1, account, admin_role, %System{})
      {:ok, _} = Membership.assign(user_2, account, viewer_role, %System{})

      response = request("/account.get_members", %{id: account.id})

      assert response["success"] == true
      # created two users for the given account
      assert length(response["data"]["data"]) == 2

      assert Enum.member?(response["data"]["data"], %{
               "object" => "user",
               "id" => user_1.id,
               "socket_topic" => "user:#{user_1.id}",
               "username" => user_1.username,
               "full_name" => user_1.full_name,
               "calling_name" => user_1.calling_name,
               "provider_user_id" => user_1.provider_user_id,
               "email" => user_1.email,
               "metadata" => user_1.metadata,
               "encrypted_metadata" => %{},
               "created_at" => DateFormatter.to_iso8601(user_1.inserted_at),
               "updated_at" => DateFormatter.to_iso8601(user_1.updated_at),
               "account_role" => "admin",
               "status" => to_string(User.get_status(user_1)),
               "enabled" => user_1.enabled,
               "enabled_2fa_at" => nil,
               "avatar" => %{
                 "original" => nil,
                 "large" => nil,
                 "small" => nil,
                 "thumb" => nil
               },
               "account" => %{
                 "avatar" => %{"large" => nil, "original" => nil, "small" => nil, "thumb" => nil},
                 "categories" => %{"data" => [], "object" => "list"},
                 "category_ids" => [],
                 "description" => account.description,
                 "encrypted_metadata" => %{},
                 "id" => account.id,
                 "master" => false,
                 "metadata" => %{},
                 "name" => account.name,
                 "object" => "account",
                 "parent_id" => nil,
                 "socket_topic" => "account:#{account.id}",
                 "created_at" => DateFormatter.to_iso8601(account.inserted_at),
                 "updated_at" => DateFormatter.to_iso8601(account.updated_at)
               }
             })

      assert Enum.member?(response["data"]["data"], %{
               "object" => "user",
               "id" => user_2.id,
               "socket_topic" => "user:#{user_2.id}",
               "username" => user_2.username,
               "full_name" => user_2.full_name,
               "calling_name" => user_2.calling_name,
               "provider_user_id" => user_2.provider_user_id,
               "email" => user_2.email,
               "metadata" => user_2.metadata,
               "encrypted_metadata" => %{},
               "created_at" => DateFormatter.to_iso8601(user_2.inserted_at),
               "updated_at" => DateFormatter.to_iso8601(user_2.updated_at),
               "account_role" => "viewer",
               "status" => to_string(User.get_status(user_2)),
               "enabled" => user_2.enabled,
               "enabled_2fa_at" => nil,
               "avatar" => %{
                 "original" => nil,
                 "large" => nil,
                 "small" => nil,
                 "thumb" => nil
               },
               "account" => %{
                 "avatar" => %{"large" => nil, "original" => nil, "small" => nil, "thumb" => nil},
                 "categories" => %{"data" => [], "object" => "list"},
                 "category_ids" => [],
                 "description" => account.description,
                 "encrypted_metadata" => %{},
                 "id" => account.id,
                 "master" => false,
                 "metadata" => %{},
                 "name" => account.name,
                 "object" => "account",
                 "parent_id" => nil,
                 "socket_topic" => "account:#{account.id}",
                 "created_at" => DateFormatter.to_iso8601(account.inserted_at),
                 "updated_at" => DateFormatter.to_iso8601(account.updated_at)
               }
             })
    end

    test_with_auths "returns unauthorized error if account id could not be found" do
      assert request("/account.get_members", %{
               id: "acc_12345678901234567890123456"
             }) ==
               %{
                 "success" => false,
                 "version" => "1",
                 "data" => %{
                   "object" => "error",
                   "code" => "unauthorized",
                   "description" => "You are not allowed to perform the requested operation.",
                   "messages" => nil
                 }
               }
    end

    test_with_auths "returns invalid_parameter error if account id is not provided" do
      assert request("/account.get_members", %{}) ==
               %{
                 "success" => false,
                 "version" => "1",
                 "data" => %{
                   "object" => "error",
                   "code" => "client:invalid_parameter",
                   "description" => "Invalid parameter provided. `id` is required.",
                   "messages" => nil
                 }
               }
    end

    # This is a variation of `ConnCase.test_supports_match_any/5` that inserts
    # an admin and a membership in order for the inserted admin to appear in the result.
    test_with_auths "supports match_any filtering on the user fields" do
      admin_1 = insert(:admin, username: "value_1")
      admin_2 = insert(:admin, username: "value_2")
      admin_3 = insert(:admin, username: "value_3")
      admin_4 = insert(:admin, username: "value_4")
      account = insert(:account)

      {:ok, _} = Membership.assign(admin_1, account, "admin", %System{})
      {:ok, _} = Membership.assign(admin_2, account, "admin", %System{})
      {:ok, _} = Membership.assign(admin_3, account, "admin", %System{})
      {:ok, _} = Membership.assign(admin_4, account, "admin", %System{})

      attrs = %{
        "id" => account.id,
        "match_any" => [
          # Filter for `user.username`
          %{
            "field" => "username",
            "comparator" => "eq",
            "value" => "value_2"
          },
          # Filter for `user.username`
          %{
            "field" => "username",
            "comparator" => "eq",
            "value" => "value_4"
          }
        ]
      }

      response = request("/account.get_members", attrs)

      assert response["success"]

      records = response["data"]["data"]

      refute Enum.any?(records, fn r -> r["id"] == admin_1.id end)
      assert Enum.any?(records, fn r -> r["id"] == admin_2.id end)
      refute Enum.any?(records, fn r -> r["id"] == admin_3.id end)
      assert Enum.any?(records, fn r -> r["id"] == admin_4.id end)
      assert Enum.count(records) == 2
    end

    # This is a variation of `ConnCase.test_supports_match_any/5` that inserts
    # an admin and a membership in order for the inserted admin to appear in the result.
    test_with_auths "supports match_any filtering on the membership fields" do
      admin_1 = insert(:admin, username: "value_1")
      admin_2 = insert(:admin, username: "value_2")
      admin_3 = insert(:admin, username: "value_3")
      account = insert(:account)
      role_1 = Role.get_by(name: "admin")
      role_2 = insert(:role, name: "viewer")

      {:ok, _} = Membership.assign(admin_1, account, role_1, %System{})
      {:ok, _} = Membership.assign(admin_2, account, role_2, %System{})
      {:ok, _} = Membership.assign(admin_3, account, role_1, %System{})

      attrs = %{
        "id" => account.id,
        "match_any" => [
          # Filter for `membership.role.name`
          %{
            "field" => "role.name",
            "comparator" => "eq",
            "value" => role_1.name
          },
          # Filter for `user.username`
          %{
            "field" => "username",
            "comparator" => "eq",
            "value" => admin_3.username
          }
        ]
      }

      response = request("/account.get_members", attrs)

      assert response["success"]

      records = response["data"]["data"]

      assert Enum.any?(records, fn r -> r["id"] == admin_1.id end)
      refute Enum.any?(records, fn r -> r["id"] == admin_2.id end)
      assert Enum.any?(records, fn r -> r["id"] == admin_3.id end)
      assert Enum.count(records) == 2
    end

    # This is a variation of `ConnCase.test_supports_match_all/5` that inserts
    # an admin and a membership in order for the inserted admin to appear in the result.
    test_with_auths "supports match_all filtering on user fields" do
      admin_1 = insert(:admin, %{username: "this_should_almost_match"})
      admin_2 = insert(:admin, %{username: "this_should_match"})
      admin_3 = insert(:admin, %{username: "should_not_match"})
      admin_4 = insert(:admin, %{username: "also_should_not_match"})
      account = insert(:account)

      {:ok, _} = Membership.assign(admin_1, account, "admin", %System{})
      {:ok, _} = Membership.assign(admin_2, account, "admin", %System{})
      {:ok, _} = Membership.assign(admin_3, account, "admin", %System{})
      {:ok, _} = Membership.assign(admin_4, account, "admin", %System{})

      attrs = %{
        "id" => account.id,
        "match_all" => [
          # Filter for `user.username`
          %{
            "field" => "username",
            "comparator" => "starts_with",
            "value" => "this_should"
          },
          # Filter for `user.username`
          %{
            "field" => "username",
            "comparator" => "contains",
            "value" => "should_match"
          }
        ]
      }

      response = request("/account.get_members", attrs)

      assert response["success"]

      records = response["data"]["data"]
      refute Enum.any?(records, fn r -> r["id"] == admin_1.id end)
      assert Enum.any?(records, fn r -> r["id"] == admin_2.id end)
      refute Enum.any?(records, fn r -> r["id"] == admin_3.id end)
      refute Enum.any?(records, fn r -> r["id"] == admin_4.id end)
      assert Enum.count(records) == 1
    end

    # This is a variation of `ConnCase.test_supports_match_any/5` that inserts
    # an admin and a membership in order for the inserted admin to appear in the result.
    test_with_auths "supports match_all filtering on membership fields" do
      admin_1 = insert(:admin)
      admin_2 = insert(:admin)
      admin_3 = insert(:admin)
      account = insert(:account)
      role_1 = Role.get_by(name: "admin")
      role_2 = insert(:role, name: "viewer")

      {:ok, _} = Membership.assign(admin_1, account, role_1, %System{})
      {:ok, _} = Membership.assign(admin_2, account, role_1, %System{})
      {:ok, _} = Membership.assign(admin_3, account, role_2, %System{})

      attrs = %{
        "id" => account.id,
        "match_all" => [
          # Filter for `membership.role.name`
          %{
            "field" => "role.name",
            "comparator" => "eq",
            "value" => role_1.name
          },
          # Filter for `membership.id`
          %{
            "field" => "id",
            "comparator" => "eq",
            "value" => admin_1.id
          }
        ]
      }

      response = request("/account.get_members", attrs)

      assert response["success"]

      records = response["data"]["data"]
      assert Enum.any?(records, fn r -> r["id"] == admin_1.id end)
      refute Enum.any?(records, fn r -> r["id"] == admin_2.id end)
      refute Enum.any?(records, fn r -> r["id"] == admin_3.id end)
      assert Enum.count(records) == 1
    end
  end
end
