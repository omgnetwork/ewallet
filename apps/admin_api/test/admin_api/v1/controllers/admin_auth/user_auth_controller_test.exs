defmodule AdminAPI.V1.AdminAuth.UserAuthControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWalletDB.{AuthToken, User}

  describe "/user.login" do
    test "responds with a new auth token if id is valid" do
      {:ok, user} = :user |> params_for() |> User.insert()
      response = admin_user_request("/user.login", %{id: user.id})
      auth_token = get_last_inserted(AuthToken)

      assert response["version"] == @expected_version
      assert response["success"] == true

      assert response["data"]["object"] == "authentication_token"
      assert response["data"]["authentication_token"] == auth_token.token
      assert response["data"]["user_id"] == user.id
      assert response["data"]["user"]["id"] == user.id
    end

    test "responds with a new auth token if provider_user_id is valid" do
      user = insert(:user, %{provider_user_id: "1234"})
      response = admin_user_request("/user.login", %{provider_user_id: "1234"})
      auth_token = get_last_inserted(AuthToken)

      assert response["data"]["object"] == "authentication_token"
      assert response["data"]["authentication_token"] == auth_token.token
      assert response["data"]["user_id"] == user.id
      assert response["data"]["user"]["provider_user_id"] == user.provider_user_id
    end

    test "returns an error if provider_user_id does not match a user" do
      response = admin_user_request("/user.login", %{provider_user_id: "not_a_user"})

      expected = %{
        "version" => @expected_version,
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "user:provider_user_id_not_found",
          "description" => "There is no user corresponding to the provided provider_user_id.",
          "messages" => nil
        }
      }

      assert response == expected
    end

    test "returns :invalid_parameter if provider_user_id is nil" do
      response = admin_user_request("/user.login", %{provider_user_id: nil})

      expected = %{
        "version" => @expected_version,
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "user:provider_user_id_not_found",
          "description" => "There is no user corresponding to the provided provider_user_id.",
          "messages" => nil
        }
      }

      assert response == expected
    end

    test "returns :invalid_parameter if provider_user_id is not provided" do
      response = admin_user_request("/user.login", %{wrong_attr: "user1234"})

      expected = %{
        "version" => @expected_version,
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "client:invalid_parameter",
          "description" => "Invalid parameter provided. `id` or `provider_user_id` is required.",
          "messages" => nil
        }
      }

      assert response == expected
    end
  end

  describe "/user.logout" do
    test "responds success with empty response if logout successfully" do
      _user = insert(:user, %{provider_user_id: "1234"})
      admin_user_request("/user.login", %{provider_user_id: "1234"})
      auth_token = get_last_inserted(AuthToken)

      response =
        admin_user_request("/user.logout", %{
          "auth_token" => auth_token.token
        })

      assert response["version"] == @expected_version
      assert response["success"] == true
      assert response["data"] == %{}
    end
  end
end
