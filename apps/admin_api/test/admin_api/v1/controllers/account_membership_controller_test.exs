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

defmodule AdminAPI.V1.AccountMembershipControllerTest do
  use AdminAPI.ConnCase, async: true
  alias Ecto.UUID
  alias Utils.Helpers.DateFormatter
  alias EWalletDB.{Role, User, Key, Membership, Repo}
  alias ActivityLogger.System

  @redirect_url "http://localhost:4000/invite?email={email}&token={token}"

  describe "/account.get_admin_user_memberships" do
    test_with_auths "returns a list of admin user memberships" do
      account = insert(:account)

      {:ok, user_1} = :admin |> params_for() |> User.insert()
      {:ok, user_2} = :admin |> params_for() |> User.insert()

      admin_role = Role.get_by(name: "admin")
      viewer_role = insert(:role, name: "viewer")

      {:ok, m_1} = Membership.assign(user_1, account, admin_role, %System{})
      {:ok, m_2} = Membership.assign(user_2, account, viewer_role, %System{})

      response = request("/account.get_admin_user_memberships", %{id: account.id})

      assert response["success"] == true
      # created two users for the given account
      assert length(response["data"]["data"]) == 2

      assert Enum.member?(response["data"]["data"], %{
               "object" => "membership",
               "user_id" => user_1.id,
               "user" => %{
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
                 "status" => to_string(User.get_status(user_1)),
                 "global_role" => user_1.global_role,
                 "enabled" => user_1.enabled,
                 "avatar" => %{
                   "original" => nil,
                   "large" => nil,
                   "small" => nil,
                   "thumb" => nil
                 }
               },
               "key_id" => nil,
               "key" => nil,
               "account_id" => account.id,
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
               },
               "role" => admin_role.name,
               "created_at" => DateFormatter.to_iso8601(m_1.inserted_at),
               "updated_at" => DateFormatter.to_iso8601(m_1.updated_at)
             })

      assert Enum.member?(response["data"]["data"], %{
               "object" => "membership",
               "user_id" => user_2.id,
               "user" => %{
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
                 "status" => to_string(User.get_status(user_2)),
                 "global_role" => user_2.global_role,
                 "enabled" => user_2.enabled,
                 "avatar" => %{
                   "original" => nil,
                   "large" => nil,
                   "small" => nil,
                   "thumb" => nil
                 }
               },
               "key_id" => nil,
               "key" => nil,
               "account_id" => account.id,
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
               },
               "role" => viewer_role.name,
               "created_at" => DateFormatter.to_iso8601(m_2.inserted_at),
               "updated_at" => DateFormatter.to_iso8601(m_2.updated_at)
             })
    end

    test_with_auths "returns unauthorized error if account id could not be found" do
      assert request("/account.get_admin_user_memberships", %{
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
      assert request("/account.get_admin_user_memberships", %{}) ==
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
            "field" => "user.username",
            "comparator" => "eq",
            "value" => "value_2"
          },
          # Filter for `user.username`
          %{
            "field" => "user.username",
            "comparator" => "eq",
            "value" => "value_4"
          }
        ]
      }

      response = request("/account.get_admin_user_memberships", attrs)

      assert response["success"]

      records = response["data"]["data"]

      refute Enum.any?(records, fn r -> r["user_id"] == admin_1.id end)
      assert Enum.any?(records, fn r -> r["user_id"] == admin_2.id end)
      refute Enum.any?(records, fn r -> r["user_id"] == admin_3.id end)
      assert Enum.any?(records, fn r -> r["user_id"] == admin_4.id end)
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
            "field" => "user.username",
            "comparator" => "eq",
            "value" => admin_3.username
          }
        ]
      }

      response = request("/account.get_admin_user_memberships", attrs)

      assert response["success"]

      records = response["data"]["data"]

      assert Enum.any?(records, fn r -> r["user_id"] == admin_1.id end)
      refute Enum.any?(records, fn r -> r["user_id"] == admin_2.id end)
      assert Enum.any?(records, fn r -> r["user_id"] == admin_3.id end)
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
            "field" => "user.username",
            "comparator" => "starts_with",
            "value" => "this_should"
          },
          # Filter for `user.username`
          %{
            "field" => "user.username",
            "comparator" => "contains",
            "value" => "should_match"
          }
        ]
      }

      response = request("/account.get_admin_user_memberships", attrs)

      assert response["success"]

      records = response["data"]["data"]
      refute Enum.any?(records, fn r -> r["user_id"] == admin_1.id end)
      assert Enum.any?(records, fn r -> r["user_id"] == admin_2.id end)
      refute Enum.any?(records, fn r -> r["user_id"] == admin_3.id end)
      refute Enum.any?(records, fn r -> r["user_id"] == admin_4.id end)
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
            "field" => "user.id",
            "comparator" => "eq",
            "value" => admin_1.id
          }
        ]
      }

      response = request("/account.get_admin_user_memberships", attrs)

      assert response["success"]

      records = response["data"]["data"]
      assert Enum.any?(records, fn r -> r["user_id"] == admin_1.id end)
      refute Enum.any?(records, fn r -> r["user_id"] == admin_2.id end)
      refute Enum.any?(records, fn r -> r["user_id"] == admin_3.id end)
      assert Enum.count(records) == 1
    end
  end

  describe "/account.get_key_memberships" do
    test_with_auths "returns a list of keys with role and status" do
      account = insert(:account)

      {:ok, key_1} = :key |> params_for() |> Key.insert()
      {:ok, key_2} = :key |> params_for() |> Key.insert()

      admin_role = Role.get_by(name: "admin")
      viewer_role = insert(:role, name: "viewer")

      {:ok, m_1} = Membership.assign(key_1, account, admin_role, %System{})
      {:ok, m_2} = Membership.assign(key_2, account, viewer_role, %System{})

      response = request("/account.get_key_memberships", %{id: account.id})

      assert response["success"] == true
      # created two keys for the given account
      assert length(response["data"]["data"]) == 2

      assert Enum.member?(response["data"]["data"], %{
               "object" => "membership",
               "user_id" => nil,
               "user" => nil,
               "key_id" => key_1.id,
               "key" => %{
                 "object" => "key",
                 "id" => key_1.id,
                 "name" => key_1.name,
                 "access_key" => key_1.access_key,
                 "secret_key" => nil,
                 "created_at" => DateFormatter.to_iso8601(key_1.inserted_at),
                 "updated_at" => DateFormatter.to_iso8601(key_1.updated_at),
                 "deleted_at" => DateFormatter.to_iso8601(key_1.deleted_at),
                 "global_role" => key_1.global_role,
                 "enabled" => key_1.enabled,
                 "expired" => !key_1.enabled,
                 "account_id" => nil
               },
               "account_id" => account.id,
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
               },
               "role" => admin_role.name,
               "created_at" => DateFormatter.to_iso8601(m_1.inserted_at),
               "updated_at" => DateFormatter.to_iso8601(m_1.updated_at)
             })

      assert Enum.member?(response["data"]["data"], %{
               "object" => "membership",
               "user_id" => nil,
               "user" => nil,
               "key_id" => key_2.id,
               "key" => %{
                 "object" => "key",
                 "id" => key_2.id,
                 "name" => key_2.name,
                 "access_key" => key_2.access_key,
                 "secret_key" => nil,
                 "created_at" => DateFormatter.to_iso8601(key_2.inserted_at),
                 "updated_at" => DateFormatter.to_iso8601(key_2.updated_at),
                 "deleted_at" => DateFormatter.to_iso8601(key_2.deleted_at),
                 "global_role" => key_2.global_role,
                 "enabled" => key_2.enabled,
                 "expired" => !key_2.enabled,
                 "account_id" => nil
               },
               "account_id" => account.id,
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
               },
               "role" => viewer_role.name,
               "created_at" => DateFormatter.to_iso8601(m_2.inserted_at),
               "updated_at" => DateFormatter.to_iso8601(m_2.updated_at)
             })
    end

    test_with_auths "returns unauthorized error if account id was not be found" do
      assert request("/account.get_key_memberships", %{
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
      assert request("/account.get_key_memberships", %{}) ==
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
    test_with_auths "supports match_any filtering on the key fields" do
      key_1 = insert(:key, name: "value_1")
      key_2 = insert(:key, name: "value_2")
      key_3 = insert(:key, name: "value_3")
      key_4 = insert(:key, name: "value_4")
      account = insert(:account)

      {:ok, _} = Membership.assign(key_1, account, "admin", %System{})
      {:ok, _} = Membership.assign(key_2, account, "admin", %System{})
      {:ok, _} = Membership.assign(key_3, account, "admin", %System{})
      {:ok, _} = Membership.assign(key_4, account, "admin", %System{})

      attrs = %{
        "id" => account.id,
        "match_any" => [
          # Filter for `key.name`
          %{
            "field" => "key.name",
            "comparator" => "eq",
            "value" => "value_2"
          },
          # Filter for `key.name`
          %{
            "field" => "key.name",
            "comparator" => "eq",
            "value" => "value_4"
          }
        ]
      }

      response = request("/account.get_key_memberships", attrs)

      assert response["success"]

      records = response["data"]["data"]

      refute Enum.any?(records, fn r -> r["key_id"] == key_1.id end)
      assert Enum.any?(records, fn r -> r["key_id"] == key_2.id end)
      refute Enum.any?(records, fn r -> r["key_id"] == key_3.id end)
      assert Enum.any?(records, fn r -> r["key_id"] == key_4.id end)
      assert Enum.count(records) == 2
    end

    # This is a variation of `ConnCase.test_supports_match_any/5` that inserts
    # a key and a membership in order for the inserted admin to appear in the result.
    test_with_auths "supports match_any filtering on the membership fields" do
      key_1 = insert(:key, name: "value_1")
      key_2 = insert(:key, name: "value_2")
      key_3 = insert(:key, name: "value_3")
      account = insert(:account)
      role_1 = Role.get_by(name: "admin")
      role_2 = insert(:role, name: "viewer")

      {:ok, _} = Membership.assign(key_1, account, role_1, %System{})
      {:ok, _} = Membership.assign(key_2, account, role_2, %System{})
      {:ok, _} = Membership.assign(key_3, account, role_1, %System{})

      attrs = %{
        "id" => account.id,
        "match_any" => [
          # Filter for `membership.role.name`
          %{
            "field" => "role.name",
            "comparator" => "eq",
            "value" => role_1.name
          },
          # Filter for `key.name`
          %{
            "field" => "key.name",
            "comparator" => "eq",
            "value" => key_3.name
          }
        ]
      }

      response = request("/account.get_key_memberships", attrs)

      assert response["success"]

      records = response["data"]["data"]

      assert Enum.any?(records, fn r -> r["key_id"] == key_1.id end)
      refute Enum.any?(records, fn r -> r["key_id"] == key_2.id end)
      assert Enum.any?(records, fn r -> r["key_id"] == key_3.id end)
      assert Enum.count(records) == 2
    end

    # This is a variation of `ConnCase.test_supports_match_all/5` that inserts
    # a key and a membership in order for the inserted admin to appear in the result.
    test_with_auths "supports match_all filtering on key fields" do
      key_1 = insert(:key, %{name: "this_should_almost_match"})
      key_2 = insert(:key, %{name: "this_should_match"})
      key_3 = insert(:key, %{name: "should_not_match"})
      key_4 = insert(:key, %{name: "also_should_not_match"})
      account = insert(:account)

      {:ok, _} = Membership.assign(key_1, account, "admin", %System{})
      {:ok, _} = Membership.assign(key_2, account, "admin", %System{})
      {:ok, _} = Membership.assign(key_3, account, "admin", %System{})
      {:ok, _} = Membership.assign(key_4, account, "admin", %System{})

      attrs = %{
        "id" => account.id,
        "match_all" => [
          # Filter for `key.name`
          %{
            "field" => "key.name",
            "comparator" => "starts_with",
            "value" => "this_should"
          },
          # Filter for `key.name`
          %{
            "field" => "key.name",
            "comparator" => "contains",
            "value" => "should_match"
          }
        ]
      }

      response = request("/account.get_key_memberships", attrs)

      assert response["success"]

      records = response["data"]["data"]
      refute Enum.any?(records, fn r -> r["key_id"] == key_1.id end)
      assert Enum.any?(records, fn r -> r["key_id"] == key_2.id end)
      refute Enum.any?(records, fn r -> r["key_id"] == key_3.id end)
      refute Enum.any?(records, fn r -> r["key_id"] == key_4.id end)
      assert Enum.count(records) == 1
    end

    # This is a variation of `ConnCase.test_supports_match_any/5` that inserts
    # a key and a membership in order for the inserted admin to appear in the result.
    test_with_auths "supports match_all filtering on membership fields" do
      key_1 = insert(:key)
      key_2 = insert(:key)
      key_3 = insert(:key)
      account = insert(:account)
      role_1 = Role.get_by(name: "admin")
      role_2 = insert(:role, name: "viewer")

      {:ok, _} = Membership.assign(key_1, account, role_1, %System{})
      :timer.sleep(10)
      {:ok, membership} = Membership.assign(key_2, account, role_1, %System{})
      {:ok, _} = Membership.assign(key_3, account, role_2, %System{})

      attrs = %{
        "id" => account.id,
        "match_all" => [
          # Filter for `membership.role.name`
          %{
            "field" => "role.name",
            "comparator" => "eq",
            "value" => role_1.name
          },
          # Filter for `membership.created_at`
          %{
            "field" => "created_at",
            "comparator" => "lt",
            "value" => DateFormatter.to_iso8601(membership.inserted_at)
          }
        ]
      }

      response = request("/account.get_key_memberships", attrs)

      assert response["success"]

      records = response["data"]["data"]
      assert Enum.any?(records, fn r -> r["key_id"] == key_1.id end)
      refute Enum.any?(records, fn r -> r["key_id"] == key_2.id end)
      refute Enum.any?(records, fn r -> r["key_id"] == key_3.id end)
      assert Enum.count(records) == 1
    end
  end

  describe "/account.assign_key" do
    test_with_auths "returns empty success if assigned with key_id successfully" do
      response =
        request("/account.assign_key", %{
          key_id: insert(:key).id,
          account_id: insert(:account).id,
          role_name: Role.get_by(name: "admin").name
        })

      assert response["success"] == true
      assert response["data"] == %{}
    end

    test_with_auths "returns an error when key_id is missing" do
      response =
        request("/account.assign_key", %{
          account_id: insert(:account).id,
          role_name: Role.get_by(name: "admin").name
        })

      refute response["success"]
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test_with_auths "returns unauthorized when key_id is not found" do
      response =
        request("/account.assign_key", %{
          key_id: "something",
          account_id: insert(:account).id,
          role_name: Role.get_by(name: "admin").name
        })

      refute response["success"]
      assert response["data"]["code"] == "unauthorized"
    end

    test_with_auths "returns unauthorized when account_id is not found" do
      response =
        request("/account.assign_key", %{
          key_id: insert(:key).id,
          account_id: "something",
          role_name: Role.get_by(name: "admin").name
        })

      refute response["success"]
      assert response["data"]["code"] == "unauthorized"
    end

    test_with_auths "returns an error when role_name is not found" do
      response =
        request("/account.assign_key", %{
          key_id: insert(:key).id,
          account_id: insert(:account).id,
          role_name: "something"
        })

      refute response["success"]
      assert response["data"]["code"] == "role:name_not_found"
    end

    test_with_auths "returns empty success if assigned as admin with the rights" do
      set_admin_user_role("admin")
      set_key_role("admin")

      account_1 = insert(:account)
      account_2 = insert(:account)

      key = insert(:key)

      # Having a membership on account_1 gives access to the target key to the actor
      {:ok, _} = Membership.assign(get_test_admin(), account_1, "admin", %System{})
      {:ok, _} = Membership.assign(get_test_key(), account_1, "admin", %System{})

      # Having a membership on account_2 gives access to the account to the actor
      {:ok, _} = Membership.assign(get_test_admin(), account_2, "admin", %System{})
      {:ok, _} = Membership.assign(get_test_key(), account_2, "admin", %System{})

      {:ok, _} = Membership.assign(key, account_1, "admin", %System{})

      response =
        request("/account.assign_key", %{
          key_id: key.id,
          account_id: account_2.id,
          role_name: Role.get_by(name: "admin").name
        })

      assert response["success"] == true
      assert response["data"] == %{}
    end

    test_with_auths "returns unauthorized if adding to an account without the rights" do
      set_admin_user_role("admin")
      set_key_role("admin")

      response =
        request("/account.assign_key", %{
          key_id: insert(:key).id,
          account_id: insert(:account).id,
          role_name: Role.get_by(name: "admin").name
        })

      assert response["success"] == false
      assert response["data"]["code"] == "unauthorized"
    end
  end

  describe "/account.unassign_key" do
    test_with_auths "returns empty success if unassigned with key_id successfully" do
      key = insert(:key)
      account = insert(:account)

      {:ok, _} = Membership.assign(key, account, "admin", %System{})

      response =
        request("/account.unassign_key", %{
          key_id: key.id,
          account_id: account.id
        })

      assert response["success"] == true
      assert response["data"] == %{}
    end

    test_with_auths "returns an error when key_id is missing" do
      response =
        request("/account.unassign_key", %{
          account_id: insert(:account).id
        })

      refute response["success"]
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test_with_auths "returns unauthorized when key_id is not found" do
      response =
        request("/account.unassign_key", %{
          key_id: "something",
          account_id: insert(:account).id
        })

      refute response["success"]
      assert response["data"]["code"] == "unauthorized"
    end

    test_with_auths "returns unauthorized when account_id is not found" do
      response =
        request("/account.unassign_key", %{
          key_id: insert(:key).id,
          account_id: "something"
        })

      refute response["success"]
      assert response["data"]["code"] == "unauthorized"
    end

    test_with_auths "returns empty success if unassigned as admin with the rights" do
      set_admin_user_role("admin")
      set_key_role("admin")

      account_1 = insert(:account)
      key = insert(:key)

      # Having a membership on account_1 gives access to the target key to the actor
      {:ok, _} = Membership.assign(get_test_admin(), account_1, "admin", %System{})
      {:ok, _} = Membership.assign(get_test_key(), account_1, "admin", %System{})

      {:ok, _} = Membership.assign(key, account_1, "admin", %System{})

      response =
        request("/account.unassign_key", %{
          key_id: key.id,
          account_id: account_1.id
        })

      assert response["success"] == true
      assert response["data"] == %{}
    end

    test_with_auths "returns unauthorized if adding to an account without the rights" do
      set_admin_user_role("admin")
      set_key_role("admin")

      response =
        request("/account.unassign_key", %{
          key_id: insert(:key).id,
          account_id: insert(:account).id
        })

      assert response["success"] == false
      assert response["data"]["code"] == "unauthorized"
    end
  end

  describe "/account.assign_user" do
    test_with_auths "returns empty success if assigned with user_id successfully" do
      {:ok, user} = :user |> params_for() |> User.insert()

      response =
        request("/account.assign_user", %{
          user_id: user.id,
          account_id: insert(:account).id,
          role_name: Role.get_by(name: "admin").name,
          redirect_url: @redirect_url
        })

      assert response["success"] == true
      assert response["data"] == %{}
    end

    test_with_auths "returns empty success if assigned with email successfully" do
      response =
        request("/account.assign_user", %{
          email: insert(:admin).email,
          account_id: insert(:account).id,
          role_name: Role.get_by(name: "admin").name,
          redirect_url: @redirect_url
        })

      assert response["success"] == true
      assert response["data"] == %{}
    end

    test_with_auths "returns empty success if the user has a pending confirmation" do
      email = "user_pending_confirmation@example.com"
      admin = get_test_admin()
      account = insert(:account)
      role = Role.get_by(name: "admin")
      {:ok, _} = Membership.assign(admin, account, role, %System{})

      response =
        request("/account.assign_user", %{
          email: email,
          account_id: account.id,
          role_name: role.name,
          redirect_url: @redirect_url
        })

      # Make sure that the first attemps created the user with pending_confirmation status
      assert response["success"] == true
      user = User.get_by(email: email)
      assert User.get_status(user) == :pending_confirmation

      response =
        request("/account.assign_user", %{
          email: email,
          account_id: account.id,
          role_name: role.name,
          redirect_url: @redirect_url
        })

      # The second attempt should also be successful
      assert response["success"] == true
      assert response["data"] == %{}
    end

    test_with_auths "returns an error if the email format is invalid" do
      response =
        request("/account.assign_user", %{
          email: "invalid_format",
          account_id: insert(:account).id,
          role_name: Role.get_by(name: "admin").name,
          redirect_url: @redirect_url
        })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:invalid_email"
      assert response["data"]["description"] == "The format of the provided email is invalid."
    end

    test_with_auths "returns an error if the email is nil" do
      response =
        request("/account.assign_user", %{
          email: nil,
          account_id: insert(:account).id,
          role_name: Role.get_by(name: "admin").name,
          redirect_url: @redirect_url
        })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:invalid_email"
      assert response["data"]["description"] == "The format of the provided email is invalid."
    end

    test_with_auths "returns client:invalid_parameter error if the redirect_url is not allowed" do
      redirect_url = "http://unknown-url.com/invite?email={email}&token={token}"

      response =
        request("/account.assign_user", %{
          email: "wrong.redirect.url@example.com",
          account_id: insert(:account).id,
          role_name: Role.get_by(name: "admin").name,
          redirect_url: redirect_url
        })

      refute response["success"]
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "The given `redirect_url` is not allowed. Got: '#{redirect_url}'."
    end

    test_with_auths "returns an 'unauthorized' error if the given user id does not exist" do
      response =
        request("/account.assign_user", %{
          user_id: UUID.generate(),
          account_id: insert(:account).id,
          role_name: Role.get_by(name: "admin").name,
          redirect_url: @redirect_url
        })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end

    test_with_auths "returns an error if the given account id does not exist" do
      {:ok, user} = :user |> params_for() |> User.insert()

      response =
        request("/account.assign_user", %{
          user_id: user.id,
          account_id: "acc_12345678901234567890123456",
          role_name: Role.get_by(name: "admin").name,
          redirect_url: @redirect_url
        })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"

      assert response["data"]["description"] ==
               "You are not allowed to perform the requested operation."
    end

    test_with_auths "returns an error if the given role does not exist" do
      {:ok, user} = :user |> params_for() |> User.insert()

      response =
        request("/account.assign_user", %{
          user_id: user.id,
          account_id: insert(:account).id,
          role_name: "invalid_role",
          redirect_url: @redirect_url
        })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "role:name_not_found"

      assert response["data"]["description"] ==
               "There is no role corresponding to the provided name."
    end

    defp assert_assign_user_logs(logs, originator, target) do
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: originator,
        target: target,
        changes: %{
          "account_uuid" => target.account.uuid,
          "role_uuid" => target.role.uuid,
          "user_uuid" => target.user.uuid
        },
        encrypted_changes: %{}
      )
    end

    test "generates an activity log for an admin request" do
      {:ok, user} = :user |> params_for() |> User.insert()
      account = insert(:account)
      role = Role.get_by(name: "admin")
      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/account.assign_user", %{
          user_id: user.id,
          account_id: account.id,
          role_name: role.name,
          redirect_url: @redirect_url
        })

      assert response["success"] == true
      membership = Membership |> get_last_inserted() |> Repo.preload([:account, :role, :user])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_assign_user_logs(get_test_admin(), membership)
    end

    test "generates an activity log for a provider request" do
      {:ok, user} = :user |> params_for() |> User.insert()
      account = insert(:account)
      role = Role.get_by(name: "admin")
      timestamp = DateTime.utc_now()

      response =
        provider_request("/account.assign_user", %{
          user_id: user.id,
          account_id: account.id,
          role_name: role.name,
          redirect_url: @redirect_url
        })

      assert response["success"] == true
      membership = Membership |> get_last_inserted() |> Repo.preload([:account, :role, :user])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_assign_user_logs(get_test_key(), membership)
    end
  end

  describe "/account.unassign_user" do
    test_with_auths "returns empty success if unassigned successfully" do
      account = insert(:account)
      add_admin_to_account(account)
      {:ok, user} = :user |> params_for() |> User.insert()
      {:ok, _} = Membership.assign(user, account, "admin", %System{})

      response =
        request("/account.unassign_user", %{
          user_id: user.id,
          account_id: account.id
        })

      assert response["success"] == true
      assert response["data"] == %{}
    end

    test_with_auths "returns an error if the user was not previously assigned to the account" do
      {:ok, user} = :user |> params_for() |> User.insert()
      account = insert(:account)

      response =
        request("/account.unassign_user", %{
          user_id: user.id,
          account_id: account.id
        })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end

    test_with_auths "returns an error if the given user id does not exist" do
      response =
        request("/account.unassign_user", %{
          user_id: UUID.generate(),
          account_id: insert(:account).id
        })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end

    test_with_auths "returns an error if the given account id does not exist" do
      {:ok, user} = :user |> params_for() |> User.insert()

      response =
        request("/account.unassign_user", %{
          user_id: user.id,
          account_id: "acc_12345678901234567890123456"
        })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"

      assert response["data"]["description"] ==
               "You are not allowed to perform the requested operation."
    end

    defp assert_unassign_logs(logs, originator, target) do
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "delete",
        originator: originator,
        target: target,
        changes: %{},
        encrypted_changes: %{}
      )
    end

    test "generates an activity log for an admin request" do
      account = insert(:account)
      {:ok, user} = :user |> params_for() |> User.insert()
      {:ok, membership} = Membership.assign(user, account, "admin", %System{})

      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/account.unassign_user", %{
          user_id: user.id,
          account_id: account.id
        })

      assert response["success"] == true

      timestamp
      |> get_all_activity_logs_since()
      |> assert_unassign_logs(get_test_admin(), membership)
    end

    test "generates an activity log for a provider request" do
      account = insert(:account)
      {:ok, user} = :user |> params_for() |> User.insert()
      {:ok, membership} = Membership.assign(user, account, "admin", %System{})

      timestamp = DateTime.utc_now()

      response =
        provider_request("/account.unassign_user", %{
          user_id: user.id,
          account_id: account.id
        })

      assert response["success"] == true

      timestamp
      |> get_all_activity_logs_since()
      |> assert_unassign_logs(get_test_key(), membership)
    end
  end
end
