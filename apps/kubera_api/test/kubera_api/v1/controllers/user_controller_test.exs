defmodule KuberaAPI.V1.UserControllerTest do
  use KuberaAPI.ConnCase, async: true
  use KuberaAPI.EndpointCase, :v1
  import KuberaDB.Factory
  alias KuberaDB.Repo
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  describe "/user.create" do
    test "creates and responds with a newly created user if attributes are valid" do
      request_data = params_for(:user)

      response = build_conn()
        |> put_req_header("accept", @header_accept)
        |> post("/user.create", request_data)
        |> json_response(:ok)

      assert response["version"] == @expected_version
      assert response["success"] == :true
      assert Map.has_key?(response["data"], "id")
      data = response["data"]
      assert data["object"] == "user"
      assert data["provider_user_id"] == request_data.provider_user_id
      assert data["username"] == request_data.username
      metadata = data["metadata"]
      assert metadata["first_name"] == request_data.metadata["first_name"]
      assert metadata["last_name"] == request_data.metadata["last_name"]
    end

    test "returns an error and does not create a user if provider_user_id is not provided" do
      request_data = params_for(:user, provider_user_id: "")

      response = build_conn()
      |> put_req_header("accept", @header_accept)
      |> post("/user.create", request_data)
      |> json_response(:ok)

      assert response["version"] == @expected_version
      assert response["success"] == :false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided. `provider_user_id` can't be blank."
      assert response["data"]["messages"] == %{"provider_user_id" => ["required"]}
    end
  end

  describe "/user.get" do
    test "responds with user data if the user is found by its provider_user_id" do
      {:ok, inserted_user} = :user
                             |> build(provider_user_id: "provider_id_1")
                             |> Repo.insert

      response = build_conn()
        |> put_req_header("accept", @header_accept)
        |> post("/user.get", provider_user_id: inserted_user.provider_user_id)
        |> json_response(:ok)

      expected = %{
        "version" => @expected_version,
        "success" => true,
        "data" => %{
          "object" => "user",
          "id" => inserted_user.id,
          "provider_user_id" => inserted_user.provider_user_id,
          "username" => inserted_user.username,
          "metadata" => %{
            "first_name" => inserted_user.metadata["first_name"],
            "last_name" => inserted_user.metadata["last_name"]
          }
        }
      }

      assert response == expected
    end

    test "responds with an error if user is not found by provider_user_id" do
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

      response = build_conn()
        |> put_req_header("accept", @header_accept)
        |> post("/user.get", provider_user_id: "unknown_id999")
        |> json_response(:ok)

      assert response == expected
    end
  end
end
