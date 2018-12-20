defmodule AdminAPI.V1.ProviderAuth.ActivityControllerTest do
  use AdminAPI.ConnCase, async: true

  describe "/activity_log.all" do
    test "returns a list of activity_logs and pagination data" do
      response = provider_request("/activity_log.all")

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

    test "returns a list of activity_logs according to search_term, sort_by and sort_direction" do
      insert(:activity_log, %{action: "Matched 2"})
      insert(:activity_log, %{action: "Matched 3"})
      insert(:activity_log, %{action: "Matched 1"})
      insert(:activity_log, %{action: "Missed 1"})

      attrs = %{
        # Search is case-insensitive
        "search_term" => "MaTcHed",
        "sort_by" => "action",
        "sort_dir" => "desc"
      }

      response = provider_request("/activity_log.all", attrs)
      activity_logs = response["data"]["data"]

      assert response["success"]
      assert Enum.count(activity_logs) == 3
      assert Enum.at(activity_logs, 0)["action"] == "Matched 3"
      assert Enum.at(activity_logs, 1)["action"] == "Matched 2"
      assert Enum.at(activity_logs, 2)["action"] == "Matched 1"
    end

    test_supports_match_any("/activity_log.all", :admin_auth, :activity_log, :action)
    test_supports_match_all("/activity_log.all", :admin_auth, :activity_log, :action)
  end

  test "returns unauthorized error if the admin is not from the master account" do
    key = insert(:key)
    opts = [access_key: key.access_key, secret_key: key.secret_key]

    response = provider_request("/activity_log.all", %{}, opts)

    assert response ==
             %{
               "success" => false,
               "version" => "1",
               "data" => %{
                 "object" => "error",
                 "code" => "unauthorized",
                 "description" => "You are not allowed to perform the requested operation.",
                 "messages" => nil
               }
             }
  end
end
