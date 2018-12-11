defmodule AdminAPI.V1.AdminAuth.ConfigurationControllerTest do
  use AdminAPI.ConnCase, async: true

  describe "/configuration.get" do
    test "returns a list of settings and pagination data" do
      response = admin_user_request("/configuration.get", %{})

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

    test "returns a list of settings" do
      response =
        admin_user_request("/configuration.get", %{
          per_page: 100,
          sort_by: "position",
          sort_dir: "asc"
        })

      assert response["success"] == true
      assert length(response["data"]["data"]) == 19
      assert response["data"]["pagination"]["count"] == 19

      first_setting = Enum.at(response["data"]["data"], 0)
      last_setting = Enum.at(response["data"]["data"], -1)

      assert first_setting["key"] == "base_url"
      assert first_setting["position"] == 1

      assert last_setting["key"] == "aws_secret_access_key"
      assert last_setting["position"] == 19
    end
  end

  describe "/configuration.update" do
    test "updates one setting", meta do
      response =
        admin_user_request("/configuration.update", %{
          base_url: "new_base_url.example",
          config_pid: meta[:config_pid]
        })

      assert response["success"] == true
      assert response["data"]["data"]["base_url"] != nil
      assert response["data"]["data"]["base_url"]["value"] == "new_base_url.example"
    end

    test "updates a list of settings", meta do
      response =
        admin_user_request("/configuration.update", %{
          "aws_access_key_id" => "asd",
          "aws_bucket" => "asd",
          "aws_region" => "asdz",
          "aws_secret_access_key" => "asdasdasdasdasd",
          "config_pid" => meta[:config_pid]
        })

      assert response["success"] == true
      data = response["data"]["data"]

      assert data["aws_access_key_id"]["value"] == "asd"
      assert data["aws_bucket"]["value"] == "asd"
      assert data["aws_region"]["value"] == "asdz"
      assert data["aws_secret_access_key"]["value"] == "asdasdasdasdasd"
    end

    test "updates a list of settings with failures", meta do
      response =
        admin_user_request("/configuration.update", %{
          base_url: "new_base_url.example",
          redirect_url_prefixes: ["new_base_url.example", "something.else"],
          fake_setting: "my_value",
          max_per_page: true,
          email_adapter: "fake",
          config_pid: meta[:config_pid]
        })

      assert response["success"] == true
      data = response["data"]["data"]

      assert data["base_url"] != nil
      assert data["base_url"]["value"] == "new_base_url.example"

      assert data["redirect_url_prefixes"] != nil
      assert data["redirect_url_prefixes"]["value"] == ["new_base_url.example", "something.else"]

      assert data["email_adapter"] == %{
               "code" => "client:invalid_parameter",
               "description" =>
                 "Invalid parameter provided. `value` must be one of 'smtp', 'local', 'test'.",
               "messages" => %{"value" => ["value_not_allowed"]},
               "object" => "error"
             }

      assert data["fake_setting"] == %{
               "code" => "setting:not_found",
               "object" => "error",
               "description" => "The setting could not be inserted.",
               "messages" => nil
             }

      assert data["max_per_page"] == %{
               "code" => "client:invalid_parameter",
               "description" => "Invalid parameter provided. `value` must be of type 'integer'.",
               "messages" => %{"value" => ["invalid_type_for_value"]},
               "object" => "error"
             }
    end

    test "reloads app env", meta do
      response =
        admin_user_request("/configuration.update", %{
          base_url: "new_base_url.example",
          config_pid: meta[:config_pid]
        })

      assert response["success"] == true

      assert Application.get_env(:admin_api, :base_url, "new_base_url.example")
    end
  end
end
