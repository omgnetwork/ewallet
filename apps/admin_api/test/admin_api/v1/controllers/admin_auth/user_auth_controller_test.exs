defmodule AdminAPI.V1.AdminAuthUserAuthControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWalletDB.AuthToken

  describe "/user.login" do
    test "responds with a new auth token if id is valid" do
      user = insert(:user)
      response = admin_user_request("/user.login", %{id: user.id})
      auth_token = get_last_inserted(AuthToken)

      expected = %{
        "version" => @expected_version,
        "success" => true,
        "data" => %{
          "object" => "authentication_token",
          "authentication_token" => auth_token.token
        }
      }

      assert response == expected
    end

    test "responds with a new auth token if provider_user_id is valid" do
      _user = insert(:user, %{provider_user_id: "1234"})
      response = admin_user_request("/user.login", %{provider_user_id: "1234"})
      auth_token = get_last_inserted(AuthToken)

      expected = %{
        "version" => @expected_version,
        "success" => true,
        "data" => %{
          "object" => "authentication_token",
          "authentication_token" => auth_token.token
        }
      }

      assert response == expected
    end

    test "returns an error if provider_user_id does not match a user" do
      response = admin_user_request("/user.login", %{provider_user_id: "not_a_user"})

      expected = %{
        "version" => @expected_version,
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "user:provider_user_id_not_found",
          "description" => "There is no user corresponding to the provided provider_user_id",
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
          "code" => "client:invalid_parameter",
          "description" => "Invalid parameter provided",
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
          "description" => "Invalid parameter provided",
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
