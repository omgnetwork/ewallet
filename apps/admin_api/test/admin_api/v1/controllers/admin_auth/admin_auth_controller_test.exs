defmodule AdminAPI.V1.AdminAuth.AdminAuthControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.Web.V1.{UserSerializer, AccountSerializer}
  alias EWalletDB.{Repo, AuthToken, Membership, Role, Account}

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
      {:ok, _} = Membership.unassign(user, Enum.at(user.accounts, 0))
      account = insert(:account)
      role = Role.get_by_name("admin")
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
      {:ok, _} = Membership.unassign(user, Enum.at(user.accounts, 0))
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
      {:ok, _} = Membership.unassign(user, Enum.at(user.accounts, 0))
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
  end
end
