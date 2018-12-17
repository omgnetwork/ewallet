defmodule AdminAPI.V1.AdminAuth.AccountMembershipControllerTest do
  use AdminAPI.ConnCase, async: true
  alias Ecto.UUID
  alias EWallet.Web.Date
  alias EWalletDB.{Account, User, Membership}

  @redirect_url "http://localhost:4000/invite?email={email}&token={token}"

  describe "/account.get_members" do
    test "returns a list of users with role and status" do
      master = Account.get_master_account()
      admin = get_test_admin()
      account = insert(:account)
      {:ok, user} = :user |> params_for() |> User.insert()
      role = insert(:role)
      _ = insert(:membership, %{account: account, user: user, role: role})

      response = admin_user_request("/account.get_members", %{id: account.id})

      assert response["success"] == true
      # created user + admin user = 2
      assert length(response["data"]["data"]) == 2

      assert Enum.member?(response["data"]["data"], %{
               "object" => "user",
               "id" => user.id,
               "socket_topic" => "user:#{user.id}",
               "username" => user.username,
               "full_name" => user.full_name,
               "calling_name" => user.calling_name,
               "provider_user_id" => user.provider_user_id,
               "email" => user.email,
               "metadata" => user.metadata,
               "encrypted_metadata" => %{},
               "created_at" => Date.to_iso8601(user.inserted_at),
               "updated_at" => Date.to_iso8601(user.updated_at),
               "account_role" => role.name,
               "status" => to_string(User.get_status(user)),
               "enabled" => user.enabled,
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
                 "parent_id" => account.parent.id,
                 "socket_topic" => "account:#{account.id}",
                 "created_at" => Date.to_iso8601(account.inserted_at),
                 "updated_at" => Date.to_iso8601(account.updated_at)
               }
             })

      assert Enum.member?(response["data"]["data"], %{
               "object" => "user",
               "id" => admin.id,
               "socket_topic" => "user:#{admin.id}",
               "username" => admin.username,
               "full_name" => admin.full_name,
               "calling_name" => admin.calling_name,
               "provider_user_id" => admin.provider_user_id,
               "email" => admin.email,
               "metadata" => admin.metadata,
               "encrypted_metadata" => %{},
               "created_at" => Date.to_iso8601(admin.inserted_at),
               "updated_at" => Date.to_iso8601(admin.updated_at),
               "account_role" => "admin",
               "status" => to_string(User.get_status(admin)),
               "enabled" => admin.enabled,
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
                 "description" => master.description,
                 "encrypted_metadata" => %{},
                 "id" => master.id,
                 "master" => true,
                 "metadata" => %{},
                 "name" => master.name,
                 "object" => "account",
                 "parent_id" => nil,
                 "socket_topic" => "account:#{master.id}",
                 "created_at" => Date.to_iso8601(master.inserted_at),
                 "updated_at" => Date.to_iso8601(master.updated_at)
               }
             })
    end

    test "returns the upper admins only if the account has no members" do
      admin = get_test_admin()
      master = Account.get_master_account()
      account = insert(:account)

      assert admin_user_request("/account.get_members", %{id: account.id}) ==
               %{
                 "version" => "1",
                 "success" => true,
                 "data" => %{
                   "object" => "list",
                   "data" => [
                     %{
                       "object" => "user",
                       "id" => admin.id,
                       "socket_topic" => "user:#{admin.id}",
                       "username" => admin.username,
                       "full_name" => admin.full_name,
                       "calling_name" => admin.calling_name,
                       "provider_user_id" => admin.provider_user_id,
                       "email" => admin.email,
                       "metadata" => admin.metadata,
                       "encrypted_metadata" => %{},
                       "created_at" => Date.to_iso8601(admin.inserted_at),
                       "updated_at" => Date.to_iso8601(admin.updated_at),
                       "account_role" => "admin",
                       "status" => to_string(User.get_status(admin)),
                       "enabled" => admin.enabled,
                       "avatar" => %{
                         "original" => nil,
                         "large" => nil,
                         "small" => nil,
                         "thumb" => nil
                       },
                       "account" => %{
                         "avatar" => %{
                           "large" => nil,
                           "original" => nil,
                           "small" => nil,
                           "thumb" => nil
                         },
                         "categories" => %{"data" => [], "object" => "list"},
                         "category_ids" => [],
                         "description" => master.description,
                         "encrypted_metadata" => %{},
                         "id" => master.id,
                         "master" => true,
                         "metadata" => %{},
                         "name" => master.name,
                         "object" => "account",
                         "parent_id" => nil,
                         "socket_topic" => "account:#{master.id}",
                         "created_at" => Date.to_iso8601(master.inserted_at),
                         "updated_at" => Date.to_iso8601(master.updated_at)
                       }
                     }
                   ]
                 }
               }
    end

    test "returns unauthorized error if account id could not be found" do
      assert admin_user_request("/account.get_members", %{
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

    test "returns invalid_parameter error if account id is not provided" do
      assert admin_user_request("/account.get_members", %{}) ==
               %{
                 "success" => false,
                 "version" => "1",
                 "data" => %{
                   "object" => "error",
                   "code" => "client:invalid_parameter",
                   "description" => "Invalid parameter provided.",
                   "messages" => nil
                 }
               }
    end

    # This is a variation of `ConnCase.test_supports_match_any/5` that inserts
    # an admin and a membership in order for the inserted admin to appear in the result.
    test "supports match_any filtering on the user fields" do
      admin_1 = insert(:admin, username: "value_1")
      admin_2 = insert(:admin, username: "value_2")
      admin_3 = insert(:admin, username: "value_3")
      admin_4 = insert(:admin, username: "value_4")
      account = insert(:account)

      _ = insert(:membership, %{user: admin_1, account: account})
      _ = insert(:membership, %{user: admin_2, account: account})
      _ = insert(:membership, %{user: admin_3, account: account})
      _ = insert(:membership, %{user: admin_4, account: account})

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

      response = admin_user_request("/account.get_members", attrs)

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
    test "supports match_any filtering on the membership fields" do
      admin_1 = insert(:admin, username: "value_1")
      admin_2 = insert(:admin, username: "value_2")
      admin_3 = insert(:admin, username: "value_3")
      account = insert(:account)
      role_1 = insert(:role)
      role_2 = insert(:role)

      _ = insert(:membership, %{user: admin_1, account: account, role: role_1})
      _ = insert(:membership, %{user: admin_2, account: account, role: role_2})
      _ = insert(:membership, %{user: admin_3, account: account, role: role_2})

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

      response = admin_user_request("/account.get_members", attrs)

      assert response["success"]

      records = response["data"]["data"]

      assert Enum.any?(records, fn r -> r["id"] == admin_1.id end)
      refute Enum.any?(records, fn r -> r["id"] == admin_2.id end)
      assert Enum.any?(records, fn r -> r["id"] == admin_3.id end)
      assert Enum.count(records) == 2
    end

    # This is a variation of `ConnCase.test_supports_match_all/5` that inserts
    # an admin and a membership in order for the inserted admin to appear in the result.
    test "supports match_all filtering on user fields" do
      admin_1 = insert(:admin, %{username: "this_should_almost_match"})
      admin_2 = insert(:admin, %{username: "this_should_match"})
      admin_3 = insert(:admin, %{username: "should_not_match"})
      admin_4 = insert(:admin, %{username: "also_should_not_match"})
      account = insert(:account)

      _ = insert(:membership, %{user: admin_1, account: account})
      _ = insert(:membership, %{user: admin_2, account: account})
      _ = insert(:membership, %{user: admin_3, account: account})
      _ = insert(:membership, %{user: admin_4, account: account})

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

      response = admin_user_request("/account.get_members", attrs)

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
    test "supports match_all filtering on membership fields" do
      admin_1 = insert(:admin)
      admin_2 = insert(:admin)
      admin_3 = insert(:admin)
      account = insert(:account)
      role_1 = insert(:role)
      role_2 = insert(:role)

      _ = insert(:membership, %{user: admin_1, account: account, role: role_1})
      _ = insert(:membership, %{user: admin_2, account: account, role: role_1})
      _ = insert(:membership, %{user: admin_3, account: account, role: role_2})

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

      response = admin_user_request("/account.get_members", attrs)

      assert response["success"]

      records = response["data"]["data"]
      assert Enum.any?(records, fn r -> r["id"] == admin_1.id end)
      refute Enum.any?(records, fn r -> r["id"] == admin_2.id end)
      refute Enum.any?(records, fn r -> r["id"] == admin_3.id end)
      assert Enum.count(records) == 1
    end
  end

  describe "/account.assign_user" do
    test "returns empty success if assigned with user_id successfully" do
      {:ok, user} = :user |> params_for() |> User.insert()

      response =
        admin_user_request("/account.assign_user", %{
          user_id: user.id,
          account_id: insert(:account).id,
          role_name: insert(:role).name,
          redirect_url: @redirect_url
        })

      assert response["success"] == true
      assert response["data"] == %{}
    end

    test "returns empty success if assigned with email successfully" do
      response =
        admin_user_request("/account.assign_user", %{
          email: insert(:admin).email,
          account_id: insert(:account).id,
          role_name: insert(:role).name,
          redirect_url: @redirect_url
        })

      assert response["success"] == true
      assert response["data"] == %{}
    end

    test "returns empty success if the user has a pending confirmation" do
      email = "user_pending_confirmation@example.com"
      account = insert(:account)
      role = insert(:role)

      response =
        admin_user_request("/account.assign_user", %{
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
        admin_user_request("/account.assign_user", %{
          email: email,
          account_id: account.id,
          role_name: role.name,
          redirect_url: @redirect_url
        })

      # The second attempt should also be successful
      assert response["success"] == true
      assert response["data"] == %{}
    end

    test "returns an error if the email format is invalid" do
      response =
        admin_user_request("/account.assign_user", %{
          email: "invalid_format",
          account_id: insert(:account).id,
          role_name: insert(:role).name,
          redirect_url: @redirect_url
        })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:invalid_email"
      assert response["data"]["description"] == "The format of the provided email is invalid."
    end

    test "returns an error if the email is nil" do
      response =
        admin_user_request("/account.assign_user", %{
          email: nil,
          account_id: insert(:account).id,
          role_name: insert(:role).name,
          redirect_url: @redirect_url
        })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:invalid_email"
      assert response["data"]["description"] == "The format of the provided email is invalid."
    end

    test "returns client:invalid_parameter error if the redirect_url is not allowed" do
      redirect_url = "http://unknown-url.com/invite?email={email}&token={token}"

      response =
        admin_user_request("/account.assign_user", %{
          email: "wrong.redirect.url@example.com",
          account_id: insert(:account).id,
          role_name: insert(:role).name,
          redirect_url: redirect_url
        })

      assert response["success"] == false
      assert response["data"]["code"] == "client:invalid_parameter"

      assert response["data"]["description"] ==
               "The given `redirect_url` is not allowed. Got: '#{redirect_url}'."
    end

    test "returns an error if the given user id does not exist" do
      response =
        admin_user_request("/account.assign_user", %{
          user_id: UUID.generate(),
          account_id: insert(:account).id,
          role_name: insert(:role).name,
          redirect_url: @redirect_url
        })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:id_not_found"

      assert response["data"]["description"] ==
               "There is no user corresponding to the provided id."
    end

    test "returns an error if the given account id does not exist" do
      {:ok, user} = :user |> params_for() |> User.insert()

      response =
        admin_user_request("/account.assign_user", %{
          user_id: user.id,
          account_id: "acc_12345678901234567890123456",
          role_name: insert(:role).name,
          redirect_url: @redirect_url
        })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"

      assert response["data"]["description"] ==
               "You are not allowed to perform the requested operation."
    end

    test "returns an error if the given role does not exist" do
      {:ok, user} = :user |> params_for() |> User.insert()

      response =
        admin_user_request("/account.assign_user", %{
          user_id: user.id,
          account_id: insert(:account).id,
          role_name: "invalid_role",
          redirect_url: @redirect_url
        })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "role:name_not_found"

      assert response["data"]["description"] ==
               "There is no role corresponding to the provided name."
    end

    test "generates an activity log" do
      {:ok, user} = :user |> params_for() |> User.insert()
      account = insert(:account)
      role = insert(:role)
      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/account.assign_user", %{
          user_id: user.id,
          account_id: account.id,
          role_name: role.name,
          redirect_url: @redirect_url
        })

      assert response["success"] == true
      membership = get_last_inserted(Membership)
      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: get_test_admin(),
        target: membership,
        changes: %{
          "account_uuid" => account.uuid,
          "role_uuid" => role.uuid,
          "user_uuid" => user.uuid
        },
        encrypted_changes: %{}
      )
    end
  end

  describe "/account.unassign_user" do
    test "returns empty success if unassigned successfully" do
      account = insert(:account)
      {:ok, user} = :user |> params_for() |> User.insert()
      _membership = insert(:membership, %{account: account, user: user})

      response =
        admin_user_request("/account.unassign_user", %{
          user_id: user.id,
          account_id: account.id
        })

      assert response["success"] == true
      assert response["data"] == %{}
    end

    test "returns an error if the user was not previously assigned to the account" do
      {:ok, user} = :user |> params_for() |> User.insert()
      account = insert(:account)

      response =
        admin_user_request("/account.unassign_user", %{
          user_id: user.id,
          account_id: account.id
        })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "membership:not_found"

      assert response["data"]["description"] ==
               "The user is not assigned to the provided account."
    end

    test "returns an error if the given user id does not exist" do
      response =
        admin_user_request("/account.unassign_user", %{
          user_id: UUID.generate(),
          account_id: insert(:account).id
        })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:id_not_found"

      assert response["data"]["description"] ==
               "There is no user corresponding to the provided id."
    end

    test "returns an error if the given account id does not exist" do
      {:ok, user} = :user |> params_for() |> User.insert()

      response =
        admin_user_request("/account.unassign_user", %{
          user_id: user.id,
          account_id: "acc_12345678901234567890123456"
        })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"

      assert response["data"]["description"] ==
               "You are not allowed to perform the requested operation."
    end

    test "generates an activity log" do
      account = insert(:account)
      {:ok, user} = :user |> params_for() |> User.insert()
      membership = insert(:membership, %{account: account, user: user})

      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/account.unassign_user", %{
          user_id: user.id,
          account_id: account.id
        })

      assert response["success"] == true
      logs = get_all_activity_logs_since(timestamp)
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "delete",
        originator: get_test_admin(),
        target: membership,
        changes: %{},
        encrypted_changes: %{}
      )
    end
  end
end
