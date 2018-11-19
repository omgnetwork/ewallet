defmodule AdminAPI.V1.ProviderAuth.AdminControllerTest do
  use AdminAPI.ConnCase, async: true
  alias Ecto.UUID
  alias EWalletDB.{Account, User}

  describe "/admin.all" do
    test "returns a list of admins and pagination data" do
      response = provider_request("/admin.all")

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

    test "returns a list of admins according to search_term, sort_by and sort_direction" do
      account = insert(:account)
      role = insert(:role, %{name: "some_role"})
      admin1 = insert(:admin, %{email: "admin1@omise.co"})
      admin2 = insert(:admin, %{email: "admin2@omise.co"})
      admin3 = insert(:admin, %{email: "admin3@omise.co"})
      _user = insert(:user, %{email: "user1@omise.co"})

      insert(:membership, %{user: admin1, account: account, role: role})
      insert(:membership, %{user: admin2, account: account, role: role})
      insert(:membership, %{user: admin3, account: account, role: role})

      attrs = %{
        # Search is case-insensitive
        "search_term" => "AdMiN",
        "sort_by" => "email",
        "sort_dir" => "desc"
      }

      response = provider_request("/admin.all", attrs)
      admins = response["data"]["data"]

      assert response["success"]
      assert Enum.count(admins) == 3
      assert Enum.at(admins, 0)["email"] == "admin3@omise.co"
      assert Enum.at(admins, 1)["email"] == "admin2@omise.co"
      assert Enum.at(admins, 2)["email"] == "admin1@omise.co"
    end

    # This is a variation of `ConnCase.test_supports_match_any/5` that inserts
    # an admin and a membership in order for the inserted admin to appear in the result.
    test "supports match_any filtering" do
      admin_1 = insert(:admin, username: "value_1")
      admin_2 = insert(:admin, username: "value_2")
      admin_3 = insert(:admin, username: "value_3")
      admin_4 = insert(:admin, username: "value_4")

      _ = insert(:membership, %{user: admin_1})
      _ = insert(:membership, %{user: admin_2})
      _ = insert(:membership, %{user: admin_3})
      _ = insert(:membership, %{user: admin_4})

      attrs = %{
        "match_any" => [
          %{
            "field" => "username",
            "comparator" => "eq",
            "value" => "value_2"
          },
          %{
            "field" => "username",
            "comparator" => "eq",
            "value" => "value_4"
          }
        ]
      }

      response = provider_request("/admin.all", attrs)

      assert response["success"]

      records = response["data"]["data"]
      assert Enum.any?(records, fn r -> r["id"] == admin_2.id end)
      assert Enum.any?(records, fn r -> r["id"] == admin_4.id end)
      assert Enum.count(records) == 2
    end

    # This is a variation of `ConnCase.test_supports_match_all/5` that inserts
    # an admin and a membership in order for the inserted admin to appear in the result.
    test "supports match_all filtering" do
      account = Account.get_master_account()
      admin_1 = insert(:admin, %{username: "this_should_almost_match"})
      admin_2 = insert(:admin, %{username: "this_should_match"})
      admin_3 = insert(:admin, %{username: "should_not_match"})
      admin_4 = insert(:admin, %{username: "also_should_not_match"})

      _ = insert(:membership, %{user: admin_1, account: account})
      _ = insert(:membership, %{user: admin_2, account: account})
      _ = insert(:membership, %{user: admin_3, account: account})
      _ = insert(:membership, %{user: admin_4, account: account})

      attrs = %{
        "match_all" => [
          %{
            "field" => "username",
            "comparator" => "starts_with",
            "value" => "this_should"
          },
          %{
            "field" => "username",
            "comparator" => "contains",
            "value" => "should_match"
          }
        ]
      }

      response = provider_request("/admin.all", attrs)

      assert response["success"]

      records = response["data"]["data"]
      assert Enum.any?(records, fn r -> r["id"] == admin_2.id end)
      assert Enum.count(records) == 1
    end
  end

  describe "/admin.get" do
    test "returns an admin by the given admin's ID" do
      account = insert(:account)
      role = insert(:role, %{name: "some_role"})
      admin = insert(:admin, %{email: "admin@omise.co"})
      _membership = insert(:membership, %{user: admin, account: account, role: role})

      response = provider_request("/admin.get", %{"id" => admin.id})

      assert response["success"]
      assert response["data"]["object"] == "user"
      assert response["data"]["email"] == admin.email
    end

    test "returns 'unauthorized' if the given ID is not an admin" do
      {:ok, user} = :user |> params_for() |> User.insert()
      response = provider_request("/admin.get", %{"id" => user.id})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end

    test "returns 'unauthorized' if the given ID was not found" do
      response = provider_request("/admin.get", %{"id" => UUID.generate()})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end

    test "returns 'unauthorized' if the given ID format is invalid" do
      response = provider_request("/admin.get", %{"id" => "not_valid_id_format"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "unauthorized"
    end
  end
end
