defmodule EWalletAdmin.V1.AuthControllerTest do
  use EWalletAdmin.ConnCase, async: true

  describe "/login" do
    test "responds with a new auth token if the given email and password are valid" do
      response = client_request("/login", %{email: @user_email, password: @password})

      assert response["success"] == true
      assert response["data"]["object"] == "authentication_token"
      assert String.length(response["data"]["authentication_token"]) > 0
    end

    test "returns an error if the given email does not exist" do
      response = client_request("/login", %{email: "wrong_email@example.com", password: @password})

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
