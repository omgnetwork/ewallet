defmodule KuberaAPI.V1.AuthControllerTest do
  use KuberaAPI.ConnCase, async: true
  use KuberaAPI.EndpointCase, :v1

  describe "/login" do
    test "responds with a new auth token if provider_user_id is valid" do
      :user |> insert(%{provider_user_id: "1234"})
      request_data = %{provider_user_id: "1234"}

      response = build_conn()
        |> put_req_header("accept", @header_accept)
        |> put_req_header("authorization", @header_auth)
        |> post("/login", request_data)
        |> json_response(:ok)

      assert response["version"] == @expected_version
      assert response["success"] == :true
      assert response["data"]["object"] == "authentication_token"
      assert String.length(response["data"]["authentication_token"]) > 0
    end

    test "returns an error if provider_user_id does not match a user" do
      request_data = %{provider_user_id: "not_a_user"}

      response = build_conn()
      |> put_req_header("accept", @header_accept)
      |> put_req_header("authorization", @header_auth)
      |> post("/login", request_data)
      |> json_response(:ok)

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
      request_data = %{provider_user_id: nil}

      response = build_conn()
      |> put_req_header("accept", @header_accept)
      |> put_req_header("authorization", @header_auth)
      |> post("/login", request_data)
      |> json_response(:ok)

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
      request_data = %{wrong_attribute: "user1234"}

      response = build_conn()
      |> put_req_header("accept", @header_accept)
      |> put_req_header("authorization", @header_auth)
      |> post("/login", request_data)
      |> json_response(:ok)

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
      api_key = insert(:api_key).key
      auth_token = insert(:auth_token).token

      response = build_conn()
        |> put_req_header("accept", @header_accept)
        |> put_auth_header("OMGClient", api_key, auth_token)
        |> post("/logout", %{})
        |> json_response(:ok)

      assert response["version"] == @expected_version
      assert response["success"] == :true
      assert response["data"] == %{}
    end
  end
end
