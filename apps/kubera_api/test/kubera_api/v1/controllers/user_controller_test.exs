defmodule KuberaAPI.V1.UserControllerTest do
  use KuberaAPI.ConnCase, async: true
  use KuberaAPI.EndpointCase, :v1
  alias KuberaDB.{Repo, User}
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  describe "/user.create" do
    test "creates and responds with a newly created user if attributes are valid" do

      request_data = %{
        provider_user_id: "provider_id9999",
        username: "johndoe",
        metadata: %{
          first_name: "John",
          last_name: "Doe"
        }
      }

      response = build_conn()
        |> put_req_header("accept", @header_accept)
        |> post("/user.create", request_data)
        |> json_response(:ok)

      assert response["version"] == @expected_version
      assert response["success"] == :true
      assert Map.has_key?(response["data"], "id")
      assert response["data"]["object"] == "user"
      assert response["data"]["provider_user_id"] == "provider_id9999"
      assert response["data"]["username"] == "johndoe"
      assert response["data"]["metadata"]["first_name"] == "John"
      assert response["data"]["metadata"]["last_name"] == "Doe"
    end

    test "returns an error and does not create a user if provider_user_id is not provided" do
      request_data = %{
        provider_user_id: "",
        username: "johndoe",
        metadata: %{
          first_name: "John",
          last_name: "Doe"
        }
      }

      response = build_conn()
      |> put_req_header("accept", @header_accept)
      |> post("/user.create", request_data)
      |> json_response(:bad_request)

      assert response["version"] == @expected_version
      assert response["success"] == :false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "invalid_data"
      assert response["data"]["message"] == "Invalid user data"
    end
  end

  describe "/user.get" do
    test "responds with user data if the user is found" do
      user = %User{
        username: "test_username_1",
        provider_user_id: "provider_id_1",
        metadata: %{
          first_name: "John",
          last_name: "Doe"
        }
      }

      {:ok, inserted_user} = Repo.insert(user)

      response = build_conn()
        |> put_req_header("accept", @header_accept)
        |> post("/user.get", id: inserted_user.id)
        |> json_response(:ok)

      expected = %{
        "version" => @expected_version,
        "success" => true,
        "data" => %{
          "object" => "user",
          "id" => inserted_user.id,
          "provider_user_id" => user.provider_user_id,
          "username" => user.username,
          "metadata" => %{
            "first_name" => user.metadata.first_name,
            "last_name" => user.metadata.last_name
          }
        }
      }

      assert response == expected
    end

    test "responds with an error if user is not found" do
      expected = %{
        "version" => @expected_version,
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "user_not_found",
          "message" => "User not found"
        }
      }

      response = build_conn()
        |> put_req_header("accept", @header_accept)
        |> post("/user.get", id: "00000000-0000-0000-0000-000000000000")
        |> json_response(:not_found)

      assert response == expected
    end
  end
end
