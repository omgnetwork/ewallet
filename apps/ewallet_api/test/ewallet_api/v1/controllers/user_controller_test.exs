defmodule EWalletAPI.V1.UserControllerTest do
  use EWalletAPI.ConnCase, async: true

  describe "/user.create" do
    test "creates and responds with a newly created user if attributes are valid" do
      request_data = params_for(:user)
      response     = provider_request("/user.create", request_data)

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

    test "returns an error if provider_user_id is not provided" do
      request_data = params_for(:user, provider_user_id: "")
      response     = provider_request("/user.create", request_data)

      assert response["version"] == @expected_version
      assert response["success"] == :false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided. "
        <> "`provider_user_id` can't be blank."
      assert response["data"]["messages"] == %{"provider_user_id" => ["required"]}
    end

    test "returns an error if username is not provided" do
      request_data = params_for(:user, username: "")
      response     = provider_request("/user.create", request_data)

      assert response["version"] == @expected_version
      assert response["success"] == :false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided. "
        <> "`username` can't be blank."
      assert response["data"]["messages"] == %{"username" => ["required"]}
    end
  end

  describe "/user.update" do
    test "Updates the user if attributes are valid" do
      user = insert(:user)

      # Prepare the update data while keeping only provider_user_id the same
      request_data = params_for(:user, %{
        provider_user_id: user.provider_user_id,
        username: "updated_username",
        metadata: %{
          first_name: "updated_first_name",
          last_name: "updated_last_name"
        }
      })

      response = provider_request("/user.update", request_data)

      assert response["version"] == @expected_version
      assert response["success"] == :true

      data = response["data"]
      assert data["object"] == "user"
      assert data["provider_user_id"] == user.provider_user_id
      assert data["username"] == request_data.username

      metadata = data["metadata"]
      assert metadata["first_name"] == request_data.metadata.first_name
      assert metadata["last_name"] == request_data.metadata.last_name
    end

    test "returns an error if provider_user_id is not provided" do
      request_data = params_for(:user, %{provider_user_id: ""})
      response     = provider_request("/user.update", request_data)

      assert response["version"] == @expected_version
      assert response["success"] == :false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided"
    end

    test "returns an error if user for provider_user_id is not found" do
      request_data = params_for(:user, %{provider_user_id: "unknown_id"})
      response     = provider_request("/user.update", request_data)

      assert response["version"] == @expected_version
      assert response["success"] == :false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:provider_user_id_not_found"
      assert response["data"]["description"] == "There is no user corresponding to the provided provider_user_id"
    end

    test "returns an error if username is not provided" do
      user = insert(:user)

      # ExMachine will remove the param if set to nil.
      request_data = params_for(:user, %{
        provider_user_id: user.provider_user_id,
        username: nil
      })

      response = provider_request("/user.update", request_data)

      assert response["version"] == @expected_version
      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided"
    end
  end

  describe "/user.get" do
    test "responds with user data if the user is found by its provider_user_id" do
      inserted_user = insert(:user, %{provider_user_id: "provider_id_1"})
      request_data  = %{provider_user_id: inserted_user.provider_user_id}
      response      = provider_request("/user.get", request_data)

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
          },
          "encrypted_metadata" => %{}
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

      request_data = %{provider_user_id: "unknown_id999"}
      response     = provider_request("/user.get", request_data)

      assert response == expected
    end

    test "responds :invalid_parameter if provider_user_id not given" do
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

      response = provider_request("/user.get", %{})

      assert response == expected
    end

    test "responds :invalid_parameter if provider_user_id is nil" do
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

      request_data = %{provider_user_id: nil}
      response = provider_request("/user.get", request_data)

      assert response == expected
    end
  end
end
