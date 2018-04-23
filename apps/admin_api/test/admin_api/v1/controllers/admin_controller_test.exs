defmodule AdminAPI.V1.AdminControllerTest do
  use AdminAPI.ConnCase, async: true
  alias Ecto.UUID
  alias EWalletDB.User

  describe "/admin.all" do
    test "returns a list of admins and pagination data" do
      response = user_request("/admin.all")

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

    test "returns a list of admins according to search_term, sort_by and sort_direction" do
      account = insert(:account)
      role    = insert(:role, %{name: "some_role"})
      admin1  = insert(:admin, %{email: "admin1@omise.co"})
      admin2  = insert(:admin, %{email: "admin2@omise.co"})
      admin3  = insert(:admin, %{email: "admin3@omise.co"})
      _user   = insert(:user, %{email: "user1@omise.co"})

      insert(:membership, %{user: admin1, account: account, role: role})
      insert(:membership, %{user: admin2, account: account, role: role})
      insert(:membership, %{user: admin3, account: account, role: role})

      attrs = %{
        "search_term" => "AdMiN", # Search is case-insensitive
        "sort_by"     => "email",
        "sort_dir"    => "desc"
      }

      response = user_request("/admin.all", attrs)
      admins = response["data"]["data"]

      assert response["success"]
      assert Enum.count(admins) == 3
      assert Enum.at(admins, 0)["email"] == "admin3@omise.co"
      assert Enum.at(admins, 1)["email"] == "admin2@omise.co"
      assert Enum.at(admins, 2)["email"] == "admin1@omise.co"
    end
  end

  describe "/admin.get" do
    test "returns an admin by the given admin's ID" do
      account     = insert(:account)
      role        = insert(:role, %{name: "some_role"})
      admin       = insert(:admin, %{email: "admin@omise.co"})
      _membership = insert(:membership, %{user: admin, account: account, role: role})

      response = user_request("/admin.get", %{"id" => admin.id})

      assert response["success"]
      assert response["data"]["object"] == "user"
      assert response["data"]["email"] == admin.email
    end

    test "returns 'user:id_not_found' if the given ID is not an admin" do
      user     = insert(:user)
      response = user_request("/admin.get", %{"id" => user.id})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:id_not_found"
      assert response["data"]["description"] == "There is no user corresponding to the provided id"
    end

    test "returns 'user:id_not_found' if the given ID was not found" do
      response  = user_request("/admin.get", %{"id" => UUID.generate()})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:id_not_found"
      assert response["data"]["description"] == "There is no user corresponding to the provided id"
    end

    test "returns 'user:id_not_found' if the given ID format is invalid" do
      response  = user_request("/admin.get", %{"id" => "not_valid_id_format"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:id_not_found"
      assert response["data"]["description"] == "There is no user corresponding to the provided id"
    end
  end

  describe "/admin.upload_avatar" do
    test "uploads an avatar for the specified user" do
      account     = insert(:account)
      role        = insert(:role, %{name: "some_role"})
      admin       = insert(:admin, %{email: "admin@omise.co"})
      uuid        = admin.id
      _membership = insert(:membership, %{user: admin, account: account, role: role})

      response = user_request("/admin.upload_avatar", %{
        "id" => uuid,
        "avatar" => %Plug.Upload{
          path: "test/support/assets/test.jpg",
          filename: "test.jpg"
        }
      })

      assert response["success"]
      assert response["data"]["object"] == "user"
      assert response["data"]["email"] == admin.email
      assert response["data"]["avatar"]["large"] =~
             "http://localhost:4000/public/uploads/test/user/avatars/#{uuid}/large.png?v="
      assert response["data"]["avatar"]["original"] =~
             "http://localhost:4000/public/uploads/test/user/avatars/#{uuid}/original.jpg?v="
      assert response["data"]["avatar"]["small"] =~
             "http://localhost:4000/public/uploads/test/user/avatars/#{uuid}/small.png?v="
      assert response["data"]["avatar"]["thumb"] =~
             "http://localhost:4000/public/uploads/test/user/avatars/#{uuid}/thumb.png?v="
    end

    test "removes the avatar from a user" do
      account     = insert(:account)
      role        = insert(:role, %{name: "some_role"})
      admin       = insert(:admin, %{email: "admin@omise.co"})
      uuid        = admin.id
      _membership = insert(:membership, %{user: admin, account: account, role: role})

      response = user_request("/admin.upload_avatar", %{
        "id" => uuid,
        "avatar" => %Plug.Upload{
          path: "test/support/assets/test.jpg",
          filename: "test.jpg"
        }
      })
      assert response["success"]

      response = user_request("/admin.upload_avatar", %{
        "id" => uuid,
        "avatar" => nil
      })
      assert response["success"]

      admin = User.get(admin.id)
      assert admin.avatar == nil
    end

    test "removes the avatar from a user with empty string" do
      account     = insert(:account)
      role        = insert(:role, %{name: "some_role"})
      admin       = insert(:admin, %{email: "admin@omise.co"})
      uuid        = admin.id
      _membership = insert(:membership, %{user: admin, account: account, role: role})

      response = user_request("/admin.upload_avatar", %{
        "id" => uuid,
        "avatar" => %Plug.Upload{
          path: "test/support/assets/test.jpg",
          filename: "test.jpg"
        }
      })
      assert response["success"]

      response = user_request("/admin.upload_avatar", %{
        "id" => uuid,
        "avatar" => ""
      })
      assert response["success"]

      admin = User.get(admin.id)
      assert admin.avatar == nil
    end

    test "removes the avatar from a user with 'null' string" do
      account     = insert(:account)
      role        = insert(:role, %{name: "some_role"})
      admin       = insert(:admin, %{email: "admin@omise.co"})
      uuid        = admin.id
      _membership = insert(:membership, %{user: admin, account: account, role: role})

      response = user_request("/admin.upload_avatar", %{
        "id" => uuid,
        "avatar" => %Plug.Upload{
          path: "test/support/assets/test.jpg",
          filename: "test.jpg"
        }
      })
      assert response["success"]

      response = user_request("/admin.upload_avatar", %{
        "id" => uuid,
        "avatar" => "null"
      })
      assert response["success"]

      admin = User.get(admin.id)
      assert admin.avatar == nil
    end

    test "returns 'user:id_not_found' if the given ID is not an admin" do
      user     = insert(:user)
      response = user_request("/admin.upload_avatar", %{
        "id" => user.id,
        "avatar" => %Plug.Upload{
          path: "test/support/assets/test.jpg",
          filename: "test.jpg"
        }
      })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:id_not_found"
      assert response["data"]["description"] == "There is no user corresponding to the provided id"
    end

    test "returns 'user:id_not_found' if the given ID was not found" do
      response  = user_request("/admin.upload_avatar", %{
        "id" => "usr_12345678901234567890123456",
        "avatar" => %Plug.Upload{
          path: "test/support/assets/test.jpg",
          filename: "test.jpg"
        }
      })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:id_not_found"
      assert response["data"]["description"] == "There is no user corresponding to the provided id"
    end

    test "returns 'user:id_not_found' if the given ID format is invalid" do
      response  = user_request("/admin.upload_avatar", %{
        "id" => "not_valid_id_format",
        "avatar" => %Plug.Upload{
          path: "test/support/assets/test.jpg",
          filename: "test.jpg"
        }
      })

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "user:id_not_found"
      assert response["data"]["description"] == "There is no user corresponding to the provided id"
    end
  end
end
