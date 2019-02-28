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

defmodule AdminAPI.V1.AccountControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWalletDB.{Account, Membership, Repo, Role}
  alias ActivityLogger.System
  alias Utils.Helpers.DateFormatter
  alias EWalletConfig.Config

  describe "/account.all" do
    test_with_auths "returns a list of accounts and pagination data" do
      response = request("/account.all")
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

    test_with_auths "returns a list of accounts according to search_term, sort_by and sort_direction" do

      insert(:account, %{name: "Matched 2"})
      insert(:account, %{name: "Matched 3"})
      insert(:account, %{name: "Matched 1"})
      insert(:account, %{name: "Missed 1"})

      attrs = %{
        # Search is case-insensitive
        "search_term" => "MaTcHed",
        "sort_by" => "name",
        "sort_dir" => "desc"
      }

      response = request("/account.all", attrs)
      accounts = response["data"]["data"]

      assert response["success"]
      assert Enum.count(accounts) == 3
      assert Enum.at(accounts, 0)["name"] == "Matched 3"
      assert Enum.at(accounts, 1)["name"] == "Matched 2"
      assert Enum.at(accounts, 2)["name"] == "Matched 1"
    end

    test_supports_match_any("/account.all", :account, :name)
    test_supports_match_all("/account.all", :account, :name)

    test_with_auths "returns a list of accounts that the current user can access" do
      set_admin_as_none()
      master = Account.get_master_account()
      admin = get_test_admin()
      key = insert(:key)
      {:ok, _m} = Membership.unassign(admin, master, %System{})

      _acc_1 = insert(:account, name: "Account 1")
      acc_2 = insert(:account, name: "Account 2")
      acc_3 = insert(:account, name: "Account 3")
      acc_4 = insert(:account, name: "Account 4")
      _acc_5 = insert(:account, name: "Account 5")

      add_admin_to_account(acc_2, admin)
      add_admin_to_account(acc_3, admin)
      add_admin_to_account(acc_4, admin)

      add_admin_to_account(acc_2, key)
      add_admin_to_account(acc_3, key)
      add_admin_to_account(acc_4, key)

      response =
        request("/account.all", %{}, access_key: key.access_key, secret_key: key.secret_key)
      accounts = response["data"]["data"]

      assert response["success"]
      assert Enum.count(accounts) == 3
      assert Enum.any?(accounts, fn account -> account["name"] == "Account 2" end)
      assert Enum.any?(accounts, fn account -> account["name"] == "Account 3" end)
      assert Enum.any?(accounts, fn account -> account["name"] == "Account 4" end)
    end

    test_with_auths "returns only one account if the user only has one membership" do
      set_admin_as_none()
      master = Account.get_master_account()
      admin = get_test_admin()
      {:ok, _m} = Membership.unassign(admin, master, %System{})

      _acc_1 = insert(:account, name: "Account 1")
      _acc_2 = insert(:account, name: "Account 2")
      _acc_3 = insert(:account, name: "Account 3")
      _acc_4 = insert(:account, name: "Account 4")
      acc_5 = insert(:account, name: "Account 5")

      key = insert(:key)

      add_admin_to_account(acc_5, admin)
      add_admin_to_account(acc_5, key)

      response =
        request("/account.all", %{}, access_key: key.access_key, secret_key: key.secret_key)

      accounts = response["data"]["data"]

      assert response["success"]
      assert Enum.count(accounts) == 1
      assert Enum.at(accounts, 0)["name"] == "Account 5"
    end

    test "returns :invalid_parameter error when id is not given" do
      response = admin_user_request("/account.get", %{})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided. `id` is required."
    end
  end

  describe "/account.get_descendants" do
    test_with_auths "returns an empty list" do
      _account_1 = insert(:account, name: "account_1")
      account_2 = insert(:account, name: "account_2")

      attrs = %{
        "id" => account_2.id,
        "sort_by" => "name",
        "sort_dir" => "desc"
      }

      response = request("/account.get_descendants", attrs)

      accounts = response["data"]["data"]

      assert response["success"]
      assert Enum.empty?(accounts)
    end
  end

  describe "/account.get" do
    test_with_auths "returns an account by the given account's external ID if the user has
          a direct membership" do
      master = Account.get_master_account()
      admin = get_test_admin()
      role = Role.get_by(name: "admin")

      {:ok, _m} = Membership.unassign(admin, master, %System{})
      accounts = insert_list(3, :account)

      # Pick the 2nd inserted account
      target = Enum.at(accounts, 1)
      {:ok, _} = Membership.assign(admin, target, role, %System{})
      key = insert(:key)
      {:ok, _} = Membership.assign(key, target, role, %System{})

      response =
        request(
          "/account.get",
          %{"id" => target.id},
          access_key: key.access_key,
          secret_key: key.secret_key
        )

      assert response["success"]
      assert response["data"]["object"] == "account"
      assert response["data"]["name"] == target.name
    end

    test_with_auths "returns unauthorized if the user doesn't have access" do
      set_admin_as_none()
      master = Account.get_master_account()
      admin = get_test_admin()
      {:ok, _m} = Membership.unassign(admin, master, %System{})
      accounts = insert_list(3, :account)
      key_account = Enum.at(accounts, 0)
      # Pick the 2nd inserted account
      target = Enum.at(accounts, 1)
      key = insert(:key)
      {:ok, _m} = Membership.assign(key, key_account, "admin", %System{})

      response =
        request(
          "/account.get",
          %{"id" => target.id},
          access_key: key.access_key,
          secret_key: key.secret_key
        )

      refute response["success"]
      assert response["data"]["code"] == "unauthorized"
    end

    # The user should not know any information about the account it doesn't have access to.
    # So even the account is not found, the user is unauthorized to know that.
    test_with_auths "returns 'unauthorized' if the given ID is in correct format but not found" do
      response = request("/account.get", %{"id" => "acc_00000000000000000000000000"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"

      assert response["data"]["description"] ==
               "You are not allowed to perform the requested operation."
    end

    test_with_auths "returns 'unauthorized' if the given ID is not in the correct format" do
      response = request("/account.get", %{"id" => "invalid_format"})
      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"

      assert response["data"]["description"] ==
               "You are not allowed to perform the requested operation."
    end
  end

  describe "/account.create" do
    test_with_auths "creates a new account and returns it" do
      attrs = %{
        name: "A new account",
        metadata: %{something: "interesting"},
        encrypted_metadata: %{something: "secret"}
      }

      response = request("/account.create", attrs)

      assert response["success"] == true
      assert response["data"]["object"] == "account"
      assert response["data"]["name"] == attrs.name
      assert response["data"]["parent_id"] == nil
      assert response["data"]["metadata"] == %{"something" => "interesting"}
      assert response["data"]["encrypted_metadata"] == %{"something" => "secret"}
    end

    test_with_auths "returns an error if account name is not provided" do
      attrs = %{name: ""}

      response = request("/account.create", attrs)

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    defp assert_create_logs(logs, originator: originator, target: target) do
      assert Enum.count(logs) == 3

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator_type: "account",
        target_type: "wallet"
      )

      logs
      |> Enum.at(1)
      |> assert_activity_log(
        action: "insert",
        originator_type: "account",
        target_type: "wallet"
      )

      logs
      |> Enum.at(2)
      |> assert_activity_log(
        action: "insert",
        originator: originator,
        target: target,
        changes: %{
          "metadata" => %{"something" => "interesting"},
          "name" => target.name
        },
        encrypted_changes: %{
          "encrypted_metadata" => %{"something" => "secret"}
        }
      )
    end

    test "generates an activity log for an admin request" do
      user = get_test_admin()

      attrs = %{
        name: "A new account",
        metadata: %{something: "interesting"},
        encrypted_metadata: %{something: "secret"}
      }

      timestamp = DateTime.utc_now()
      response = admin_user_request("/account.create", attrs)

      assert response["success"] == true
      account = Account.get(response["data"]["id"])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_create_logs(originator: user, target: account)
    end

    test "generates an activity log for a provider request" do
      attrs = %{
        name: "A new account",
        metadata: %{something: "interesting"},
        encrypted_metadata: %{something: "secret"}
      }

      timestamp = DateTime.utc_now()
      response = provider_request("/account.create", attrs)
      assert response["success"] == true
      account = Account.get(response["data"]["id"])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_create_logs(originator: get_test_key(), target: account)
    end
  end

  describe "/account.update" do
    test_with_auths "updates the given account" do
      account = Account.get_master_account()

      attrs = %{
        id: account.id,
        name: "updated name",
        description: "updated description"
      }

      response = request("/account.update", attrs)

      assert response["success"] == true
      assert response["data"]["object"] == "account"
      assert response["data"]["name"] == attrs.name
      assert response["data"]["description"] == attrs.description
    end

    test_with_auths "updates the account's categories" do
      account = :account |> insert() |> Repo.preload(:categories)
      add_admin_to_account(account)

      categories = insert_list(2, :category)
      category = Enum.at(categories, 0).id
      assert Enum.empty?(account.categories)

      # Prepare the update data while keeping only id the same
      attrs = %{
        id: account.id,
        category_ids: [category]
      }

      response = request("/account.update", attrs)

      assert response["success"] == true
      assert response["data"]["object"] == "account"
      assert response["data"]["category_ids"] == attrs.category_ids

      assert List.first(response["data"]["categories"]["data"])["id"] == category
    end

    test_with_auths "returns a 'client:invalid_parameter' error if id is not provided" do
      attrs = params_for(:account, %{id: nil})

      response = request("/account.update", attrs)

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided."
    end

    test_with_auths "returns a 'unauthorized' error if id is invalid" do
      attrs = params_for(:account, %{id: "invalid_format"})

      response = request("/account.update", attrs)

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"

      assert response["data"]["description"] ==
               "You are not allowed to perform the requested operation."
    end

    defp assert_update_logs(logs, originator, target) do
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: originator,
        target: target,
        changes: %{
          "name" => target.name,
          "description" => target.description
        },
        encrypted_changes: %{
          "encrypted_metadata" => target.encrypted_metadata
        }
      )
    end

    test "generates an activity log for an admin request" do
      admin = get_test_admin()
      account = Account.get_master_account()

      attrs = %{
        id: account.id,
        name: "updated name",
        description: "updated description",
        encrypted_metadata: %{something: "updated secret"}
      }

      timestamp = DateTime.utc_now()
      response = admin_user_request("/account.update", attrs)
      assert response["success"] == true
      account = Account.get(response["data"]["id"])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_update_logs(admin, account)
    end

    test "generates an activity log for a provider request" do
      account = Account.get_master_account()

      attrs = %{
        id: account.id,
        name: "updated name",
        description: "updated description",
        encrypted_metadata: %{something: "updated secret"}
      }

      timestamp = DateTime.utc_now()
      response = provider_request("/account.update", attrs)
      assert response["success"] == true
      account = Account.get(response["data"]["id"])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_update_logs(get_test_key(), account)
    end
  end

  describe "/account.upload_avatar" do
    test_with_auths "uploads an avatar for the specified account" do
      account = insert(:account)
      add_admin_to_account(account)

      attrs = %{
        id: account.id,
        avatar: %Plug.Upload{
          path: "test/support/assets/test.jpg",
          filename: "test.jpg"
        }
      }

      response = request("/account.upload_avatar", attrs)

      assert response["success"]
      assert response["data"]["object"] == "account"

      assert response["data"]["avatar"]["large"] =~
               "http://localhost:4000/public/uploads/test/account/avatars/#{attrs.id}/large.png?v="

      assert response["data"]["avatar"]["original"] =~
               "http://localhost:4000/public/uploads/test/account/avatars/#{attrs.id}/original.jpg?v="

      assert response["data"]["avatar"]["small"] =~
               "http://localhost:4000/public/uploads/test/account/avatars/#{attrs.id}/small.png?v="

      assert response["data"]["avatar"]["thumb"] =~
               "http://localhost:4000/public/uploads/test/account/avatars/#{attrs.id}/thumb.png?v="
    end

    test_with_auths "fails to upload avatar with GCS adapter and an invalid configuration",
                    context do
      account = insert(:account)
      add_admin_to_account(account)

      {:ok, _} =
        Config.update(
          %{
            file_storage_adapter: "gcs",
            gcs_bucket: "bucket",
            gcs_credentials: "123",
            originator: %System{}
          },
          context[:config_pid]
        )

      response =
        request("/account.upload_avatar", %{
          "id" => account.id,
          "avatar" => %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        })

      assert response["success"] == false
      assert response["data"]["code"] == "adapter:server_not_running"
    end

    test_with_auths "fails to upload an invalid file" do
      key = insert(:key)
      account = insert(:account)
      add_admin_to_account(account)
      add_admin_to_account(account, key)

      attrs = %{
        "id" => account.id,
        "avatar" => %Plug.Upload{
          path: "test/support/assets/file.json",
          filename: "file.json"
        }
      }

      response =
        request(
          "/account.upload_avatar",
          attrs,
          access_key: key.access_key,
          secret_key: key.secret_key
        )

      refute response["success"]
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test_with_auths "returns an error when 'avatar' is not sent" do
      account = insert(:account)

      attrs = %{
        "id" => account.id
      }

      response = request("/account.upload_avatar", attrs)

      refute response["success"]
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test_with_auths "removes the avatar from an account" do
      account = insert(:account)
      add_admin_to_account(account)

      attrs = %{
        id: account.id,
        avatar: %Plug.Upload{
          path: "test/support/assets/test.jpg",
          filename: "test.jpg"
        }
      }

      response = request("/account.upload_avatar", attrs)
      assert response["success"]

      attrs = %{
        id: account.id,
        avatar: nil
      }

      response = request("/account.upload_avatar", attrs)

      assert response["success"]
      account = Account.get(attrs.id)
      assert account.avatar == nil
    end

    test_with_auths "removes the avatar from an account with empty string" do
      account = insert(:account)
      add_admin_to_account(account)

      attrs = %{
        id: account.id,
        avatar: %Plug.Upload{
          path: "test/support/assets/test.jpg",
          filename: "test.jpg"
        }
      }

      response = request("/account.upload_avatar", attrs)
      assert response["success"]

      attrs = %{
        id: account.id,
        avatar: ""
      }

      response = request("/account.upload_avatar", attrs)

      assert response["success"]
      account = Account.get(attrs.id)
      assert account.avatar == nil
    end

    test_with_auths "removes the avatar from an account with 'null' string" do
      account = insert(:account)
      add_admin_to_account(account)

      attrs = %{
        id: account.id,
        avatar: %Plug.Upload{
          path: "test/support/assets/test.jpg",
          filename: "test.jpg"
        }
      }

      response = request("/account.upload_avatar", attrs)
      assert response["success"]

      attrs = %{
        id: account.id,
        avatar: "null"
      }

      response = request("/account.upload_avatar", attrs)

      assert response["success"]
      account = Account.get(attrs.id)
      assert account.avatar == nil
    end

    test "returns :invalid_parameter error when id is not given" do
      response = admin_user_request("/account.upload_avatar", %{})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided."
    end

    test_with_auths "returns 'unauthorized' if the given account ID was not found" do
      attrs = %{
        id: "fake",
        avatar: %Plug.Upload{
          path: "test/support/assets/test.jpg",
          filename: "test.jpg"
        }
      }

      response = request("/account.upload_avatar", attrs)

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"

      assert response["data"]["description"] ==
               "You are not allowed to perform the requested operation."
    end

    defp assert_avatar_logs(logs, originator, target) do
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: originator,
        target: target,
        changes: %{
          "avatar" => %{
            "file_name" => "test.jpg",
            "updated_at" => DateFormatter.to_iso8601(target.avatar.updated_at)
          }
        },
        encrypted_changes: %{}
      )
    end

    test "generates an activity log for an admin request" do
      admin_user = get_test_admin()
      account = insert(:account)
      add_admin_to_account(account, admin_user)

      attrs = %{
        id: account.id,
        avatar: %Plug.Upload{
          path: "test/support/assets/test.jpg",
          filename: "test.jpg"
        }
      }

      timestamp = DateTime.utc_now()
      response = admin_user_request("/account.upload_avatar", attrs)
      assert response["success"] == true
      account = Account.get(account.id)

      timestamp
      |> get_all_activity_logs_since()
      |> assert_avatar_logs(admin_user, account)
    end

    test "generates an activity log for a provider request" do
      account = insert(:account)

      attrs = %{
        id: account.id,
        avatar: %Plug.Upload{
          path: "test/support/assets/test.jpg",
          filename: "test.jpg"
        }
      }

      timestamp = DateTime.utc_now()
      response = provider_request("/account.upload_avatar", attrs)
      assert response["success"] == true
      account = Account.get(account.id)

      timestamp
      |> get_all_activity_logs_since()
      |> assert_avatar_logs(get_test_key(), account)
    end
  end
end
