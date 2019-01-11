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
  alias EWalletDB.{Account, Membership, Repo, Role, User}
  alias ActivityLogger.System
  alias Utils.Helpers.DateFormatter

  describe "/account.all" do
    test "returns a list of accounts and pagination data" do
      test_with_auths("/account.all", fn {_, response} ->
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
      end)
    end

    test "returns a list of accounts according to search_term, sort_by and sort_direction" do
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

      test_with_auths(
        "/account.all",
        fn {_, response} ->
          accounts = response["data"]["data"]

          assert response["success"]
          assert Enum.count(accounts) == 3
          assert Enum.at(accounts, 0)["name"] == "Matched 3"
          assert Enum.at(accounts, 1)["name"] == "Matched 2"
          assert Enum.at(accounts, 2)["name"] == "Matched 1"
        end,
        attrs
      )
    end

    test_supports_match_any("/account.all", :account, :name)
    test_supports_match_all("/account.all", :account, :name)

    test "returns a list of accounts that the current user can access" do
      master = Account.get_master_account()
      user = get_test_admin()
      {:ok, _m} = Membership.unassign(user, master, %System{})

      role = Role.get_by(name: "admin")

      acc_1 = insert(:account, parent: master, name: "Account 1")
      acc_2 = insert(:account, parent: acc_1, name: "Account 2")
      acc_3 = insert(:account, parent: acc_2, name: "Account 3")
      _acc_4 = insert(:account, parent: acc_3, name: "Account 4")
      _acc_5 = insert(:account, parent: acc_3, name: "Account 5")

      # We add user to acc_2, so he should have access to
      # acc_2 and its descendants: acc_3, acc_4, acc_5
      {:ok, _m} = Membership.assign(user, acc_2, role, %System{})
      key = insert(:key, %{account: acc_2})

      test_with_auths(
        "/account.all",
        fn {_, response} ->
          accounts = response["data"]["data"]

          assert response["success"]
          assert Enum.count(accounts) == 4
          assert Enum.any?(accounts, fn account -> account["name"] == "Account 2" end)
          assert Enum.any?(accounts, fn account -> account["name"] == "Account 3" end)
          assert Enum.any?(accounts, fn account -> account["name"] == "Account 4" end)
          assert Enum.any?(accounts, fn account -> account["name"] == "Account 5" end)
        end,
        %{},
        access_key: key.access_key,
        secret_key: key.secret_key
      )
    end

    test "returns only one account if the user is at the last level" do
      master = Account.get_master_account()
      user = get_test_admin()
      {:ok, _m} = Membership.unassign(user, master, %System{})

      role = Role.get_by(name: "admin")

      acc_1 = insert(:account, parent: master, name: "Account 1")
      acc_2 = insert(:account, parent: acc_1, name: "Account 2")
      acc_3 = insert(:account, parent: acc_2, name: "Account 3")
      _acc_4 = insert(:account, parent: acc_3, name: "Account 4")
      acc_5 = insert(:account, parent: acc_3, name: "Account 5")

      {:ok, _m} = Membership.assign(user, acc_5, role, %System{})
      key = insert(:key, %{account: acc_5})

      test_with_auths(
        "/account.all",
        fn {_, response} ->
          accounts = response["data"]["data"]

          assert response["success"]
          assert Enum.count(accounts) == 1
          assert Enum.at(accounts, 0)["name"] == "Account 5"
        end,
        %{},
        access_key: key.access_key,
        secret_key: key.secret_key
      )
    end
  end

  describe "/account.get_descendants" do
    test "returns a list of children accounts and pagination data" do
      account = Account.get_master_account()

      test_with_auths(
        "/account.get_descendants",
        fn {_, response} ->
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
        end,
        %{id: account.id}
      )
    end

    test "returns a list of children accounts" do
      _account_1 = insert(:account, name: "account_1")
      account_2 = insert(:account, name: "account_2")
      account_3 = insert(:account, parent: account_2, name: "account_3")
      _account_4 = insert(:account, parent: account_3, name: "account_4")

      attrs = %{
        "id" => account_2.id,
        "sort_by" => "name",
        "sort_dir" => "desc"
      }

      test_with_auths(
        "/account.get_descendants",
        fn {_, response} ->
          accounts = response["data"]["data"]

          assert response["success"]
          assert Enum.count(accounts) == 3
          assert Enum.at(accounts, 0)["name"] == "account_4"
          assert Enum.at(accounts, 1)["name"] == "account_3"
          assert Enum.at(accounts, 2)["name"] == "account_2"
        end,
        attrs
      )
    end

    test "returns a list of accounts according to search_term, sort_by and sort_direction" do
      _account_1 = insert(:account, name: "account_1")
      account_2 = insert(:account, name: "account_2:matchez")
      account_3 = insert(:account, parent: account_2, name: "account_3:MaTcHed")
      _account_4 = insert(:account, parent: account_3, name: "account_4:MaTcHed")

      attrs = %{
        "id" => account_2.id,
        "search_term" => "MaTcHed",
        "sort_by" => "name",
        "sort_dir" => "desc"
      }

      test_with_auths(
        "/account.get_descendants",
        fn {_, response} ->
          accounts = response["data"]["data"]

          assert response["success"]
          assert Enum.count(accounts) == 2
          assert Enum.at(accounts, 0)["name"] == "account_4:MaTcHed"
          assert Enum.at(accounts, 1)["name"] == "account_3:MaTcHed"
        end,
        attrs
      )
    end
  end

  describe "/account.get" do
    test "returns an account by the given account's external ID if the user has
          an indirect membership" do
      account = insert(:account)
      accounts = insert_list(3, :account, parent: account)
      # Pick the 2nd inserted account
      target = Enum.at(accounts, 1)

      test_with_auths(
        "/account.get",
        fn {_, response} ->
          assert response["success"]
          assert response["data"]["object"] == "account"
          assert response["data"]["name"] == target.name
        end,
        %{"id" => target.id}
      )
    end

    test "returns an account by the given account's external ID if the user has
          a direct membership" do
      master = Account.get_master_account()
      admin = get_test_admin()
      role = Role.get_by(name: "admin")

      {:ok, _m} = Membership.unassign(admin, master, %System{})
      accounts = insert_list(3, :account)

      # Pick the 2nd inserted account
      target = Enum.at(accounts, 1)
      Membership.assign(admin, target, role, %System{})
      key = insert(:key, %{account: target})

      test_with_auths(
        "/account.get",
        fn {_, response} ->
          assert response["success"]
          assert response["data"]["object"] == "account"
          assert response["data"]["name"] == target.name
        end,
        %{"id" => target.id},
        access_key: key.access_key,
        secret_key: key.secret_key
      )
    end

    test "returns unauthorized if the user doesn't have access" do
      master = Account.get_master_account()
      user = get_test_admin()
      {:ok, _m} = Membership.unassign(user, master, %System{})
      accounts = insert_list(3, :account)
      key_account = Enum.at(accounts, 0)
      # Pick the 2nd inserted account
      target = Enum.at(accounts, 1)
      key = insert(:key, %{account: key_account})

      test_with_auths(
        "/account.get",
        fn {_, response} ->
          refute response["success"]
          assert response["data"]["code"] == "unauthorized"
        end,
        %{"id" => target.id},
        access_key: key.access_key,
        secret_key: key.secret_key
      )
    end

    # The user should not know any information about the account it doesn't have access to.
    # So even the account is not found, the user is unauthorized to know that.
    test "returns 'unauthorized' if the given ID is in correct format but not found" do
      test_with_auths(
        "/account.get",
        fn {_, response} ->
          refute response["success"]
          assert response["data"]["object"] == "error"
          assert response["data"]["code"] == "unauthorized"

          assert response["data"]["description"] ==
                   "You are not allowed to perform the requested operation."
        end,
        %{"id" => "acc_00000000000000000000000000"}
      )
    end

    test "returns 'unauthorized' if the given ID is not in the correct format" do
      test_with_auths(
        "/account.get",
        fn {_, response} ->
          refute response["success"]
          assert response["data"]["object"] == "error"
          assert response["data"]["code"] == "unauthorized"

          assert response["data"]["description"] ==
                   "You are not allowed to perform the requested operation."
        end,
        %{"id" => "invalid_format"}
      )
    end
  end

  describe "/account.create" do
    test "creates a new account and returns it" do
      parent = User.get_account(get_test_admin())

      request_data = %{
        :provider_auth => %{
          parent_id: parent.id,
          name: "Account 1",
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        },
        :admin_auth => %{
          parent_id: parent.id,
          name: "Account 2",
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        }
      }

      test_with_auths(
        "/account.create",
        fn {auth, response} ->
          assert response["success"] == true
          assert response["data"]["object"] == "account"
          assert response["data"]["name"] == request_data[auth].name
          assert response["data"]["parent_id"] == parent.id
          assert response["data"]["metadata"] == %{"something" => "interesting"}
          assert response["data"]["encrypted_metadata"] == %{"something" => "secret"}
        end,
        request_data
      )
    end

    test "creates a new account with no parent_id" do
      parent = Account.get_master_account()

      request_data = %{
        :provider_auth => %{
          name: "Account 1",
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        },
        :admin_auth => %{
          name: "Account 2",
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        }
      }

      test_with_auths(
        "/account.create",
        fn {auth, response} ->
          assert response["success"] == true
          assert response["data"]["object"] == "account"
          assert response["data"]["name"] == request_data[auth].name
          assert response["data"]["parent_id"] == parent.id
          assert response["data"]["metadata"] == %{"something" => "interesting"}
          assert response["data"]["encrypted_metadata"] == %{"something" => "secret"}
        end,
        request_data
      )
    end

    test "returns an error if account name is not provided" do
      parent = User.get_account(get_test_admin())
      request_data = %{name: "", parent_id: parent.id}

      test_with_auths(
        "/account.create",
        fn {_, response} ->
          refute response["success"]
          assert response["data"]["object"] == "error"
          assert response["data"]["code"] == "client:invalid_parameter"
        end,
        request_data
      )
    end

    test "generates an activity log" do
      user = get_test_admin()
      parent = User.get_account(user)

      request_data = %{
        :provider_auth => %{
          name: "Account 1",
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        },
        :admin_auth => %{
          name: "Account 2",
          metadata: %{something: "interesting"},
          encrypted_metadata: %{something: "secret"}
        }
      }

      assert_logs = fn logs, originator, target ->
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
            "name" => target.name,
            "parent_uuid" => parent.uuid
          },
          encrypted_changes: %{
            "encrypted_metadata" => %{"something" => "secret"}
          }
        )
      end

      timestamp = DateTime.utc_now()
      response = admin_user_request("/account.create", request_data[:provider_auth])
      assert response["success"] == true
      account = Account.get(response["data"]["id"])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_logs.(user, account)

      timestamp = DateTime.utc_now()
      response = provider_request("/account.create", request_data[:admin_auth])
      assert response["success"] == true
      account = Account.get(response["data"]["id"])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_logs.(get_test_key(), account)
    end
  end

  describe "/account.update" do
    test "updates the given account" do
      account = Account.get_master_account()

      request_data = %{
        :provider_auth => %{
          id: account.id,
          name: "updated name 1",
          description: "updated description 1"
        },
        :admin_auth => %{
          id: account.id,
          name: "updated name 2",
          description: "updated description 2"
        }
      }

      test_with_auths(
        "/account.update",
        fn {auth, response} ->
          assert response["success"] == true
          assert response["data"]["object"] == "account"
          assert response["data"]["name"] == request_data[auth].name
          assert response["data"]["description"] == request_data[auth].description
        end,
        request_data
      )
    end

    test "updates the account's categories" do
      account = :account |> insert() |> Repo.preload(:categories)
      categories = insert_list(2, :category)
      assert Enum.empty?(account.categories)

      # Prepare the update data while keeping only id the same
      request_data = %{
        :provider_auth => %{
          id: account.id,
          category_ids: [Enum.at(categories, 0).id]
        },
        :admin_auth => %{
          id: account.id,
          category_ids: [Enum.at(categories, 1).id]
        }
      }

      test_with_auths(
        "/account.update",
        fn {auth, response} ->
          assert response["success"] == true
          assert response["data"]["object"] == "account"
          assert response["data"]["category_ids"] == request_data[auth].category_ids

          assert List.first(response["data"]["categories"]["data"])["id"] ==
                   List.first(request_data[auth].category_ids)
        end,
        request_data
      )
    end

    test "returns a 'client:invalid_parameter' error if id is not provided" do
      request_data = params_for(:account, %{id: nil})

      test_with_auths(
        "/account.update",
        fn {_, response} ->
          refute response["success"]
          assert response["data"]["object"] == "error"
          assert response["data"]["code"] == "client:invalid_parameter"
          assert response["data"]["description"] == "Invalid parameter provided."
        end,
        request_data
      )
    end

    test "returns a 'unauthorized' error if id is invalid" do
      request_data = params_for(:account, %{id: "invalid_format"})

      test_with_auths(
        "/account.update",
        fn {_, response} ->
          refute response["success"]
          assert response["data"]["object"] == "error"
          assert response["data"]["code"] == "unauthorized"

          assert response["data"]["description"] ==
                   "You are not allowed to perform the requested operation."
        end,
        request_data
      )
    end

    test "generates an activity log" do
      admin = get_test_admin()
      account = Account.get_master_account()

      request_data = %{
        :provider_auth => %{
          id: account.id,
          name: "updated name 1",
          description: "updated description 1",
          encrypted_metadata: %{something: "secret 1"}
        },
        :admin_auth => %{
          id: account.id,
          name: "updated name 2",
          description: "updated description 2",
          encrypted_metadata: %{something: "secret 2"}
        }
      }

      assert_logs = fn logs, originator, target ->
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

      timestamp = DateTime.utc_now()
      response = admin_user_request("/account.update", request_data[:provider_auth])
      assert response["success"] == true
      account = Account.get(response["data"]["id"])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_logs.(admin, account)

      timestamp = DateTime.utc_now()
      response = provider_request("/account.update", request_data[:admin_auth])
      assert response["success"] == true
      account = Account.get(response["data"]["id"])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_logs.(get_test_key(), account)
    end
  end

  describe "/account.upload_avatar" do
    test "uploads an avatar for the specified account" do
      account1 = insert(:account)
      account2 = insert(:account)

      request_data = %{
        :provider_auth => %{
          id: account1.id,
          avatar: %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        },
        :admin_auth => %{
          id: account2.id,
          avatar: %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        }
      }

      test_with_auths(
        "/account.upload_avatar",
        fn {auth, response} ->
          assert response["success"]
          assert response["data"]["object"] == "account"

          assert response["data"]["avatar"]["large"] =~
                   "http://localhost:4000/public/uploads/test/account/avatars/#{
                     request_data[auth].id
                   }/large.png?v="

          assert response["data"]["avatar"]["original"] =~
                   "http://localhost:4000/public/uploads/test/account/avatars/#{
                     request_data[auth].id
                   }/original.jpg?v="

          assert response["data"]["avatar"]["small"] =~
                   "http://localhost:4000/public/uploads/test/account/avatars/#{
                     request_data[auth].id
                   }/small.png?v="

          assert response["data"]["avatar"]["thumb"] =~
                   "http://localhost:4000/public/uploads/test/account/avatars/#{
                     request_data[auth].id
                   }/thumb.png?v="
        end,
        request_data
      )
    end

    test "fails to upload an invalid file" do
      account = insert(:account)

      request_data = %{
        "id" => account.id,
        "avatar" => %Plug.Upload{
          path: "test/support/assets/file.json",
          filename: "file.json"
        }
      }

      test_with_auths(
        "/account.upload_avatar",
        fn {_, response} ->
          refute response["success"]
          assert response["data"]["code"] == "client:invalid_parameter"
        end,
        request_data
      )
    end

    test "returns an error when 'avatar' is not sent" do
      account = insert(:account)

      request_data = %{
        "id" => account.id
      }

      test_with_auths(
        "/account.upload_avatar",
        fn {_, response} ->
          refute response["success"]
          assert response["data"]["code"] == "client:invalid_parameter"
        end,
        request_data
      )
    end

    test "removes the avatar from an account" do
      account1 = insert(:account)
      account2 = insert(:account)

      request_data = %{
        :provider_auth => %{
          id: account1.id,
          avatar: %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        },
        :admin_auth => %{
          id: account2.id,
          avatar: %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        }
      }

      test_with_auths(
        "/account.upload_avatar",
        fn {_, response} ->
          assert response["success"]
        end,
        request_data
      )

      request_data = %{
        :provider_auth => %{
          id: account1.id,
          avatar: nil
        },
        :admin_auth => %{
          id: account2.id,
          avatar: nil
        }
      }

      test_with_auths(
        "/account.upload_avatar",
        fn {auth, response} ->
          assert response["success"]
          account = Account.get(request_data[auth].id)
          assert account.avatar == nil
        end,
        request_data
      )
    end

    test "removes the avatar from an account with empty string" do
      account1 = insert(:account)
      account2 = insert(:account)

      request_data = %{
        :provider_auth => %{
          id: account1.id,
          avatar: %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        },
        :admin_auth => %{
          id: account2.id,
          avatar: %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        }
      }

      test_with_auths(
        "/account.upload_avatar",
        fn {_, response} ->
          assert response["success"]
        end,
        request_data
      )

      request_data = %{
        :provider_auth => %{
          id: account1.id,
          avatar: ""
        },
        :admin_auth => %{
          id: account2.id,
          avatar: ""
        }
      }

      test_with_auths(
        "/account.upload_avatar",
        fn {auth, response} ->
          assert response["success"]
          account = Account.get(request_data[auth].id)
          assert account.avatar == nil
        end,
        request_data
      )
    end

    test "removes the avatar from an account with 'null' string" do
      account1 = insert(:account)
      account2 = insert(:account)

      request_data = %{
        :provider_auth => %{
          id: account1.id,
          avatar: %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        },
        :admin_auth => %{
          id: account2.id,
          avatar: %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        }
      }

      test_with_auths(
        "/account.upload_avatar",
        fn {_, response} ->
          assert response["success"]
        end,
        request_data
      )

      request_data = %{
        :provider_auth => %{
          id: account1.id,
          avatar: "null"
        },
        :admin_auth => %{
          id: account2.id,
          avatar: "null"
        }
      }

      test_with_auths(
        "/account.upload_avatar",
        fn {auth, response} ->
          assert response["success"]
          account = Account.get(request_data[auth].id)
          assert account.avatar == nil
        end,
        request_data
      )
    end

    test "returns 'unauthorized' if the given account ID was not found" do
      request_data = %{
        id: "fake",
        avatar: %Plug.Upload{
          path: "test/support/assets/test.jpg",
          filename: "test.jpg"
        }
      }

      test_with_auths(
        "/account.upload_avatar",
        fn {_, response} ->
          refute response["success"]
          assert response["data"]["object"] == "error"
          assert response["data"]["code"] == "unauthorized"

          assert response["data"]["description"] ==
                   "You are not allowed to perform the requested operation."
        end,
        request_data
      )
    end

    test "generates an activity log" do
      admin = get_test_admin()
      account1 = insert(:account)
      account2 = insert(:account)

      request_data = %{
        :provider_auth => %{
          id: account1.id,
          avatar: %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        },
        :admin_auth => %{
          id: account2.id,
          avatar: %Plug.Upload{
            path: "test/support/assets/test.jpg",
            filename: "test.jpg"
          }
        }
      }

      assert_logs = fn logs, originator, target ->
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

      timestamp = DateTime.utc_now()
      response = admin_user_request("/account.upload_avatar", request_data[:provider_auth])
      assert response["success"] == true
      account = Account.get(account1.id)

      timestamp
      |> get_all_activity_logs_since()
      |> assert_logs.(admin, account)

      timestamp = DateTime.utc_now()
      response = provider_request("/account.upload_avatar", request_data[:admin_auth])
      assert response["success"] == true
      account = Account.get(account2.id)

      timestamp
      |> get_all_activity_logs_since()
      |> assert_logs.(get_test_key(), account)
    end
  end
end
