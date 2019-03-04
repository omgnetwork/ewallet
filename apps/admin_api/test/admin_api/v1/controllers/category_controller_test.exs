# Copyright 2018-2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule AdminAPI.V1.CategoryControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWalletDB.{Category, Repo}
  alias EWalletDB.Helpers.Preloader
  alias ActivityLogger.System
  alias Utils.Helpers.DateFormatter

  describe "/category.all" do
    test_with_auths "returns a list of categories and pagination data" do
      response = request("/category.all")

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

    test_with_auths "returns a list of categories according to search_term, sort_by and sort_direction" do
      insert(:category, %{name: "Matched 2"})
      insert(:category, %{name: "Matched 3"})
      insert(:category, %{name: "Matched 1"})
      insert(:category, %{name: "Missed 1"})

      attrs = %{
        # Search is case-insensitive
        "search_term" => "MaTcHed",
        "sort_by" => "name",
        "sort_dir" => "desc"
      }

      response = request("/category.all", attrs)
      categories = response["data"]["data"]

      assert response["success"]
      assert Enum.count(categories) == 3
      assert Enum.at(categories, 0)["name"] == "Matched 3"
      assert Enum.at(categories, 1)["name"] == "Matched 2"
      assert Enum.at(categories, 2)["name"] == "Matched 1"
    end

    test_supports_match_any("/category.all", :category, :name)
    test_supports_match_all("/category.all", :category, :name)
  end

  describe "/category.get" do
    test_with_auths "returns an category by the given category's ID" do
      categories = insert_list(3, :category)

      # Pick the 2nd inserted category
      target = Enum.at(categories, 1)
      response = request("/category.get", %{"id" => target.id})

      assert response["success"]
      assert response["data"]["object"] == "category"
      assert response["data"]["name"] == target.name
    end

    test_with_auths "returns 'category:id_not_found' if the given ID was not found" do
      response = request("/category.get", %{"id" => "cat_12345678901234567890123456"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "category:id_not_found"

      assert response["data"]["description"] ==
               "There is no category corresponding to the provided id."
    end

    test_with_auths "returns 'category:id_not_found' if the given ID format is invalid" do
      response = request("/category.get", %{"id" => "not_an_id"})

      refute response["success"]
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "category:id_not_found"

      assert response["data"]["description"] ==
               "There is no category corresponding to the provided id."
    end
  end

  describe "/category.create" do
    test_with_auths "creates a new category and returns it" do
      request_data = %{name: "A test category"}
      response = request("/category.create", request_data)

      assert response["success"] == true
      assert response["data"]["object"] == "category"
      assert response["data"]["name"] == request_data.name
    end

    test_with_auths "returns an error if the category name is not provided" do
      request_data = %{name: ""}
      response = request("/category.create", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
    end

    defp assert_create_logs(logs, originator, target) do
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "insert",
        originator: originator,
        target: target,
        changes: %{"name" => target.name},
        encrypted_changes: %{}
      )
    end

    test "generates an activity log for an admin request" do
      timestamp = DateTime.utc_now()
      request_data = %{name: "A test category"}
      response = admin_user_request("/category.create", request_data)

      assert response["success"] == true

      category = Category.get(response["data"]["id"])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_create_logs(get_test_admin(), category)
    end

    test "generates an activity log for a provider request" do
      timestamp = DateTime.utc_now()
      request_data = %{name: "A test category"}
      response = provider_request("/category.create", request_data)

      assert response["success"] == true

      category = Category.get(response["data"]["id"])

      timestamp
      |> get_all_activity_logs_since()
      |> assert_create_logs(get_test_key(), category)
    end
  end

  describe "/category.update" do
    test_with_auths "updates the given category" do
      category = insert(:category)

      # Prepare the update data while keeping only id the same
      request_data =
        params_for(:category, %{
          id: category.id,
          name: "updated_name",
          description: "updated_description"
        })

      response = request("/category.update", request_data)

      assert response["success"] == true
      assert response["data"]["object"] == "category"
      assert response["data"]["name"] == "updated_name"
      assert response["data"]["description"] == "updated_description"
    end

    test_with_auths "updates the category's accounts" do
      category = :category |> insert() |> Preloader.preload(:accounts)
      account = :account |> insert()
      assert Enum.empty?(category.accounts)

      # Prepare the update data while keeping only id the same
      request_data = %{
        id: category.id,
        account_ids: [account.id]
      }

      response = request("/category.update", request_data)

      assert response["success"] == true
      assert response["data"]["object"] == "category"
      assert response["data"]["account_ids"] == [account.id]
      assert List.first(response["data"]["accounts"]["data"])["id"] == account.id
    end

    test_with_auths "returns a 'client:invalid_parameter' error if id is not provided" do
      request_data = params_for(:category, %{id: nil})
      response = request("/category.update", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "client:invalid_parameter"
      assert response["data"]["description"] == "Invalid parameter provided."
    end

    test_with_auths "returns an 'unauthorized' error if id is invalid" do
      request_data = params_for(:category, %{id: "invalid_format"})
      response = request("/category.update", request_data)

      assert response["success"] == false
      assert response["data"]["object"] == "error"
      assert response["data"]["code"] == "category:id_not_found"

      assert response["data"]["description"] ==
               "There is no category corresponding to the provided id."
    end

    defp assert_update_logs(logs, originator, target) do
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: originator,
        target: target,
        changes: %{"name" => target.name, "description" => target.description},
        encrypted_changes: %{}
      )
    end

    test "generates an activity log for an admin request" do
      category = insert(:category)
      timestamp = DateTime.utc_now()

      request_data =
        params_for(:category, %{
          id: category.id,
          name: "updated_name",
          description: "updated_description"
        })

      response = admin_user_request("/category.update", request_data)

      assert response["success"] == true

      category = Category.get(category.id)

      timestamp
      |> get_all_activity_logs_since()
      |> assert_update_logs(get_test_admin(), category)
    end

    test "generates an activity log for a provider request" do
      category = insert(:category)
      timestamp = DateTime.utc_now()

      request_data =
        params_for(:category, %{
          id: category.id,
          name: "updated_name",
          description: "updated_description"
        })

      response = provider_request("/category.update", request_data)

      assert response["success"] == true

      category = Category.get(category.id)

      timestamp
      |> get_all_activity_logs_since()
      |> assert_update_logs(get_test_key(), category)
    end
  end

  describe "/category.delete" do
    test_with_auths "responds success with the deleted category" do
      category = insert(:category)
      response = request("/category.delete", %{id: category.id})

      assert response["success"] == true
      assert response["data"]["object"] == "category"
      assert response["data"]["id"] == category.id
    end

    test_with_auths "responds with an error if the category has one or more associated accounts" do
      account = insert(:account)

      {:ok, category} =
        :category
        |> insert()
        |> Category.update(%{
          account_ids: [account.id],
          originator: %System{}
        })

      response = request("/category.delete", %{id: category.id})

      assert response ==
               %{
                 "version" => "1",
                 "success" => false,
                 "data" => %{
                   "code" => "category:not_empty",
                   "description" => "The category has one or more accounts associated.",
                   "messages" => nil,
                   "object" => "error"
                 }
               }
    end

    test_with_auths "responds with an error if the provided id is not found" do
      response = request("/category.delete", %{id: "wrong_id"})

      assert response ==
               %{
                 "version" => "1",
                 "success" => false,
                 "data" => %{
                   "code" => "category:id_not_found",
                   "description" => "There is no category corresponding to the provided id.",
                   "messages" => nil,
                   "object" => "error"
                 }
               }
    end

    test_with_auths "responds with an error if the user is not authorized to delete the category" do
      category = insert(:category)
      auth_token = insert(:auth_token, owner_app: "admin_api")
      key = insert(:key)

      attrs = %{id: category.id}

      opts = [
        user_id: auth_token.user.id,
        auth_token: auth_token.token,
        access_key: key.access_key,
        secret_key: key.secret_key
      ]

      response = request("/category.delete", attrs, opts)

      assert response ==
               %{
                 "version" => "1",
                 "success" => false,
                 "data" => %{
                   "code" => "unauthorized",
                   "description" => "You are not allowed to perform the requested operation.",
                   "messages" => nil,
                   "object" => "error"
                 }
               }
    end

    defp assert_delete_logs(logs, originator, target) do
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: originator,
        target: target,
        changes: %{"deleted_at" => DateFormatter.to_iso8601(target.deleted_at)},
        encrypted_changes: %{}
      )
    end

    test "generates an activity log for an admin request" do
      category = insert(:category)
      timestamp = DateTime.utc_now()

      response = admin_user_request("/category.delete", %{id: category.id})

      assert response["success"] == true

      category = Repo.get_by(Category, %{id: category.id})

      timestamp
      |> get_all_activity_logs_since()
      |> assert_delete_logs(get_test_admin(), category)
    end

    test "generates an activity log for a provider request" do
      category = insert(:category)
      timestamp = DateTime.utc_now()

      response = provider_request("/category.delete", %{id: category.id})

      assert response["success"] == true

      category = Repo.get_by(Category, %{id: category.id})

      timestamp
      |> get_all_activity_logs_since()
      |> assert_delete_logs(get_test_key(), category)
    end
  end
end
