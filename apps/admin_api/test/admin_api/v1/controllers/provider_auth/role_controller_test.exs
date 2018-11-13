defmodule AdminAPI.V1.ProviderAuth.RoleControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWalletDB.{Membership, Role}

  describe "/role.all" do
    test "returns a list of roles and pagination data" do
      response = provider_request("/role.all")

      # Asserts return data
      assert response["success"]
      assert response["data"]["object"] == "list"
      assert is_list(response["data"]["data"])

      # Asserts pagination data
      pagination = response["data"]["pagination"]
      assert is_integer(pagination["per_page"])
      assert is_integer(pagination["current_page"])
      assert is_boolean(pagination["is_last_page"])
      assert is_boolean(pagination["is_first_page"])
    end

    test "returns a list of roles according to search_term, sort_by and sort_direction" do
      insert(:role, %{name: "matched_2"})
      insert(:role, %{name: "matched_3"})
      insert(:role, %{name: "matched_1"})
      insert(:role, %{name: "missed_1"})

      attrs = %{
        # Search is case-insensitive
        "search_term" => "MaTcHed",
        "sort_by" => "name",
        "sort_dir" => "desc"
      }

      response = provider_request("/role.all", attrs)
      roles = response["data"]["data"]

      assert response["success"]
      assert Enum.count(roles) == 3
      assert Enum.at(roles, 0)["name"] == "matched_3"
      assert Enum.at(roles, 1)["name"] == "matched_2"
      assert Enum.at(roles, 2)["name"] == "matched_1"
    end
  end

  describe "/role.get" do
    test "returns an role by the given role's ID" do
      roles = insert_list(3, :role)

      # Pick the 2nd inserted role
      target = Enum.at(roles, 1)
      response = provider_request("/role.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "role"
      assert response["data"]["name"] == target.name
    end

    test "returns 'role:id_not_found' if the given ID was not found" do
      response = provider_request("/role.get", %{"id" => "rol_12345678901234567890123456"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "role:id_not_found"

      assert response["data"]["description"] ==
               "There is no role corresponding to the provided id."
    end

    test "returns 'role:id_not_found' if the given ID format is invalid" do
      response = provider_request("/role.get", %{"id" => "not_an_id"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "role:id_not_found"

      assert response["data"]["description"] ==
               "There is no role corresponding to the provided id."
    end
  end

  describe "/role.create" do
    test "creates a new role and returns it" do
      request_data = %{name: "test_role"}
      response = provider_request("/role.create", request_data)

      assert response["success"] == true
      assert response["data"]["object"] == "role"
      assert response["data"]["name"] == request_data.name
    end

    test "returns an error if the role name is not provided" do
      request_data = %{name: ""}
      response = provider_request("/role.create", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
    end
  end

  describe "/role.update" do
    test "updates the given role" do
      role = insert(:role)

      # Prepare the update data while keeping only id the same
      request_data =
        params_for(:role, %{
          id: role.id,
          name: "updated_name",
          display_name: "updated_display_name"
        })

      response = provider_request("/role.update", request_data)

      assert response["success"] == true
      assert response["data"]["object"] == "role"
      assert response["data"]["name"] == "updated_name"
      assert response["data"]["display_name"] == "updated_display_name"
    end

    test "returns a 'client:invalid_parameter' error if id is not provided" do
      request_data = params_for(:role, %{id: nil})
      response = provider_request("/role.update", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided."
    end

    test "returns an 'unauthorized' error if id is invalid" do
      request_data = params_for(:role, %{id: "invalid_format"})
      response = provider_request("/role.update", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "role:id_not_found"

      assert response["data"]["description"] ==
               "There is no role corresponding to the provided id."
    end
  end

  describe "/role.delete" do
    test "responds success with the deleted role" do
      role = insert(:role)
      response = provider_request("/role.delete", %{id: role.id})

      assert response["success"] == true
      assert response["data"]["object"] == "role"
      assert response["data"]["id"] == role.id
    end

    test "responds with an error if the role has one or more associated users" do
      user = insert(:admin)
      account = insert(:account)
      role = insert(:role, name: "test_role_not_empty")
      {:ok, _membership} = Membership.assign(user, account, role)

      users = role.id |> Role.get(preload: :users) |> Map.get(:users)
      assert Enum.count(users) > 0

      response = admin_user_request("/role.delete", %{id: role.id})

      assert response ==
               %{
                 "version" => "1",
                 "success" => false,
                 "data" => %{
                   "code" => "role:not_empty",
                   "description" => "The role has one or more users associated.",
                   "messages" => nil,
                   "object" => "error"
                 }
               }
    end

    test "responds with an error if the provided id is not found" do
      response = provider_request("/role.delete", %{id: "wrong_id"})

      assert response ==
               %{
                 "version" => "1",
                 "success" => false,
                 "data" => %{
                   "code" => "role:id_not_found",
                   "description" => "There is no role corresponding to the provided id.",
                   "messages" => nil,
                   "object" => "error"
                 }
               }
    end
  end
end
