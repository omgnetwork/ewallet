defmodule AdminAPI.V1.AccountMembershipControllerTest do
  use AdminAPI.ConnCase, async: true
  alias Ecto.UUID
  alias EWallet.Web.Date
  alias EWalletDB.User

  describe "/account.list_users" do
    test "returns a list of users with role and status" do
      account = insert(:account)
      user    = insert(:user)
      role    = insert(:role)
      _       = insert(:membership, %{account: account, user: user, role: role})

      assert user_request("/account.list_users", %{account_id: account.external_id}) ==
        %{
          "version" => "1",
          "success" => true,
          "data" => %{
            "object" => "list",
            "data" => [%{
              "object" => "user",
              "id" => user.id,
              "external_id" => user.external_id,
              "socket_topic" => "user:#{user.id}",
              "username" => user.username,
              "provider_user_id" => user.provider_user_id,
              "email" => user.email,
              "metadata" => user.metadata,
              "encrypted_metadata" => %{},
              "created_at" => Date.to_iso8601(user.inserted_at),
              "updated_at" => Date.to_iso8601(user.updated_at),
              "account_role" => role.name,
              "status" => to_string(User.get_status(user)),
              "avatar" => %{"original" => nil, "large" => nil, "small" => nil, "thumb" => nil}
            }]
          }
        }
    end

    test "returns an empty list if account has no users" do
      account = insert(:account)

      assert user_request("/account.list_users", %{account_id: account.external_id}) ==
        %{
          "version" => "1",
          "success" => true,
          "data" => %{
            "object" => "list",
            "data" => []
          }
        }
    end

    test "returns account:id_not_found error if account id could not be found" do
      assert user_request("/account.list_users", %{account_id: "acc_12345678901234567890123456"}) ==
        %{
          "success" => false,
          "version" => "1",
          "data" => %{
            "object" => "error",
            "code" => "account:id_not_found",
            "description" => "There is no account corresponding to the provided id",
            "messages" => nil
          }
        }
    end

    test "returns invalid_parameter error if account id is not provided" do
      assert user_request("/account.list_users", %{}) ==
        %{
          "success" => false,
          "version" => "1",
          "data" => %{
            "object" => "error",
            "code" => "client:invalid_parameter",
            "description" => "Invalid parameter provided",
            "messages" => nil
          }
        }
    end
  end

  describe "/account.assign_user" do
    test "returns empty success if assigned with user_id successfully" do
      response = user_request("/account.assign_user", %{
        user_id: insert(:user).id,
        account_id: insert(:account).external_id,
        role_name: insert(:role).name,
        redirect_url: "https://invite_url/?email={email}&token={token}"
      })

      assert response["success"] == true
      assert response["data"] == %{}
    end

    test "returns empty success if assigned with email successfully" do
      response = user_request("/account.assign_user", %{
        email: insert(:admin).email,
        account_id: insert(:account).external_id,
        role_name: insert(:role).name,
        redirect_url: "https://invite_url/?email={email}&token={token}"
      })

      assert response["success"] == true
      assert response["data"] == %{}
    end

    test "returns an error if the email format is invalid" do
      response = user_request("/account.assign_user", %{
        email: "invalid_format",
        account_id: insert(:account).external_id,
        role_name: insert(:role).name,
        redirect_url: "https://invite_url/?email={email}&token={token}"
      })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:invalid_email"
      assert response["data"]["description"] == "The format of the provided email is invalid"
    end

    test "returns an error if the given user id does not exist" do
      response = user_request("/account.assign_user", %{
        user_id: UUID.generate(),
        account_id: insert(:account).external_id,
        role_name: insert(:role).name,
        redirect_url: "https://invite_url/?email={email}&token={token}"
      })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:id_not_found"
      assert response["data"]["description"] == "There is no user corresponding to the provided id"
    end

    test "returns an error if the given account id does not exist" do
      response = user_request("/account.assign_user", %{
        user_id: insert(:user).id,
        account_id: "acc_12345678901234567890123456",
        role_name: insert(:role).name,
        redirect_url: "https://invite_url/?email={email}&token={token}"
      })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "account:id_not_found"
      assert response["data"]["description"] == "There is no account corresponding to the provided id"
    end

    test "returns an error if the given role does not exist" do
      response = user_request("/account.assign_user", %{
        user_id: insert(:user).id,
        account_id: insert(:account).external_id,
        role_name: "invalid_role",
        redirect_url: "https://invite_url/?email={email}&token={token}"
      })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "role:name_not_found"
      assert response["data"]["description"] == "There is no role corresponding to the provided name"
    end
  end

  describe "/account.unassign_user" do
    test "returns empty success if unassigned successfully" do
      account    = insert(:account)
      membership = insert(:membership, %{account: account})
      response   = user_request("/account.unassign_user", %{
        user_id: membership.user_id,
        account_id: account.external_id
      })

      assert response["success"] == true
      assert response["data"] == %{}
    end

    test "returns an error if the user was not previously assigned to the account" do
      user    = insert(:user)
      account = insert(:account)

      response = user_request("/account.unassign_user", %{
        user_id: user.id,
        account_id: account.external_id
      })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "membership:not_found"
      assert response["data"]["description"] == "The user is not assigned to the provided account"
    end

    test "returns an error if the given user id does not exist" do
      response = user_request("/account.unassign_user", %{
        user_id: UUID.generate(),
        account_id: insert(:account).external_id
      })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:id_not_found"
      assert response["data"]["description"] == "There is no user corresponding to the provided id"
    end

    test "returns an error if the given account id does not exist" do
      response = user_request("/account.unassign_user", %{
        user_id: insert(:user).id,
        account_id: "acc_12345678901234567890123456"
      })

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "account:id_not_found"
      assert response["data"]["description"] == "There is no account corresponding to the provided id"
    end
  end
end
