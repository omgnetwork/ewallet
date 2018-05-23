defmodule AdminAPI.V1.AuthControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWallet.Web.V1.{UserSerializer, AccountSerializer}
  alias EWalletDB.{Repo, AuthToken, Membership, Role}

  describe "/login" do
    test "responds with a new auth token if the given email and password are valid" do
      response = client_request("/login", %{email: @user_email, password: @password})
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
          "master_admin" => true
        }
      }

      assert response == expected
    end

    test "responds with a new auth token if credentials are valid but user is not master_admin" do
      user = get_test_user() |> Repo.preload([:accounts])
      {:ok, _} = Membership.unassign(user, Enum.at(user.accounts, 0))
      account = insert(:account)
      role = Role.get_by_name("admin")
      _membership = insert(:membership, %{user: user, role: role, account: account})

      response = client_request("/login", %{email: @user_email, password: @password})
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
          "master_admin" => false
        }
      }

      assert response == expected
    end

    test "returns an error if the given email does not exist" do
      response =
        client_request("/login", %{email: "wrong_email@example.com", password: @password})

      expected = %{
        "version" => @expected_version,
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "user:invalid_login_credentials",
          "description" => "There is no user corresponding to the provided login credentials",
          "messages" => nil
        }
      }

      assert response == expected
    end

    test "returns an error if the given password is incorrect" do
      response = client_request("/login", %{email: @user_email, password: "wrong_password"})

      expected = %{
        "version" => @expected_version,
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "user:invalid_login_credentials",
          "description" => "There is no user corresponding to the provided login credentials",
          "messages" => nil
        }
      }

      assert response == expected
    end

    test "returns :invalid_parameter if email is blank" do
      response = client_request("/login", %{email: "", password: @password})
      refute response["success"]
      assert response["data"]["code"] == "user:invalid_login_credentials"
    end

    test "returns :invalid_parameter if password is blank" do
      response = client_request("/login", %{email: @user_email, password: ""})
      refute response["success"]
      assert response["data"]["code"] == "user:invalid_login_credentials"
    end

    test "returns :invalid_parameter if email is missing" do
      response = client_request("/login", %{email: nil, password: @password})
      refute response["success"]
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test "returns :invalid_parameter if password is missing" do
      response = client_request("/login", %{email: @user_email, password: nil})
      refute response["success"]
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test "returns :invalid_parameter if both email and password are missing" do
      response = client_request("/login", %{foo: "bar"})
      refute response["success"]
      refute response["success"]
      assert response["data"]["code"] == "client:invalid_parameter"
    end
  end

  describe "/auth_token.switch_account" do
    test "switches the account" do
      user = get_test_user()
      account = insert(:account)

      # User belongs to the master account and has access to the sub account
      # just created
      response =
        user_request("/auth_token.switch_account", %{
          "account_id" => account.id
        })

      assert response["success"]
      assert response["data"]["user"]["id"] == user.id
      assert response["data"]["account"]["id"] == account.id
    end

    test "returns a permission error when trying to switch to an invalid account" do
      user = get_test_user() |> Repo.preload([:accounts])
      {:ok, _} = Membership.unassign(user, Enum.at(user.accounts, 0))
      account = insert(:account)

      response =
        user_request("/auth_token.switch_account", %{
          "account_id" => account.id
        })

      refute response["success"]
      assert response["data"]["code"] == "user:unauthorized"
    end

    test "returns :account_not_found when the account does not exist" do
      response =
        user_request("/auth_token.switch_account", %{
          "account_id" => "123"
        })

      refute response["success"]
      assert response["data"]["code"] == "account:not_found"
    end

    test "returns :invalid_parameter when account_id is not sent" do
      response =
        user_request("/auth_token.switch_account", %{
          "fake" => "123"
        })

      refute response["success"]
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    test "returns :invalid_api_key if client credentials are invalid" do
      response =
        user_request(
          "/auth_token.switch_account",
          %{
            "account_id" => "123"
          },
          api_key: "bad_api_key"
        )

      refute response["success"]
      assert response["data"]["code"] == "client:invalid_api_key"
    end

    test "returns :access_token_not_found if user credentials are invalid" do
      response =
        user_request(
          "/auth_token.switch_account",
          %{
            "account_id" => "123"
          },
          auth_token: "bad_auth_token"
        )

      refute response["success"]
      assert response["data"]["code"] == "user:access_token_not_found"
    end
  end

  describe "/logout" do
    test "responds success with empty response when successful" do
      response = user_request("/logout")

      expected = %{
        "version" => @expected_version,
        "success" => true,
        "data" => %{}
      }

      assert response == expected
    end

    test "prevents following calls from using the same credentials" do
      response1 = user_request("/logout")
      assert response1["success"]

      response2 = user_request("/logout")
      refute response2["success"]
      assert response2["data"]["code"] == "user:access_token_expired"
    end
  end
end
