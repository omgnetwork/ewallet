defmodule EWalletAPI.V1.AuthControllerTest do
  use EWalletAPI.ConnCase, async: true

  describe "/login" do
    test "responds with a new auth token if provider_user_id is valid" do
      insert(:user, %{provider_user_id: "1234"})
      response = provider_request("/login", %{provider_user_id: "1234"})

      assert response["success"] == :true
      assert response["data"]["object"] == "authentication_token"
      assert String.length(response["data"]["authentication_token"]) > 0
    end

    test "returns an error if provider_user_id does not match a user" do
      response = provider_request("/login", %{provider_user_id: "not_a_user"})

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
      response = provider_request("/login", %{provider_user_id: nil})

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
      response = provider_request("/login", %{wrong_attr: "user1234"})

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

  describe "/logout" do
    test "responds success with empty response if logout successfully" do
      response = client_request("/logout")

      assert response["version"] == @expected_version
      assert response["success"] == :true
      assert response["data"] == %{}
    end
  end
end
