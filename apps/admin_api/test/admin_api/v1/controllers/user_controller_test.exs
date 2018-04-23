defmodule AdminAPI.V1.UserControllerTest do
  use AdminAPI.ConnCase, async: true

  describe "/user.all" do
    test "returns a list of users and pagination data" do
      response = user_request("/user.all")

      # Asserts return data
      assert response["success"]
      assert response["data"]["object"] == "list"
      assert is_list(response["data"]["data"])

      # Asserts pagination data
      pagination = response["data"]["pagination"]
      assert is_integer pagination["per_page"]
      assert is_integer pagination["current_page"]
      assert is_boolean pagination["is_last_page"]
      assert is_boolean pagination["is_first_page"]
    end

    test "returns a list of users according to search_term, sort_by and sort_direction" do
      insert(:user, %{username: "match_user1"})
      insert(:user, %{username: "match_user3"})
      insert(:user, %{username: "match_user2"})
      insert(:user, %{username: "missed_user1"})

      attrs = %{
        "search_term" => "MaTcH", # Search is case-insensitive
        "sort_by"     => "username",
        "sort_dir"    => "desc"
      }

      response = user_request("/user.all", attrs)
      users = response["data"]["data"]

      assert response["success"]
      assert Enum.count(users) == 3
      assert Enum.at(users, 0)["username"] == "match_user3"
      assert Enum.at(users, 1)["username"] == "match_user2"
      assert Enum.at(users, 2)["username"] == "match_user1"
    end
  end

  describe "/user.get" do
    test "returns an user by the given user's ID" do
      users    = insert_list(3, :user)
      target   = Enum.at(users, 1) # Pick the 2nd inserted user
      response = user_request("/user.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "user"
      assert response["data"]["username"] == target.username
    end

    test "returns 'user:id_not_found' if the given ID was not found" do
      response  = user_request("/user.get", %{"id" => "usr_12345678901234567890123456"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:id_not_found"
      assert response["data"]["description"] == "There is no user corresponding to the provided id"
    end

    test "returns 'user:id_not_found' if the given ID format is invalid" do
      response  = user_request("/user.get", %{"id" => "not_uuid"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:id_not_found"
      assert response["data"]["description"] == "There is no user corresponding to the provided id"
    end
  end
end
