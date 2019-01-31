# Copyright 2018 OmiseGO Pte Ltd
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

defmodule AdminAPI.V1.ConfigurationControllerTest do
  use AdminAPI.ConnCase, async: true
  alias EWalletConfig.{Config, StoredSetting}

  describe "/configuration.all" do
    test_with_auths "returns a list of configurations" do
      response = request("/configuration.all", %{})
      # Asserts return data
      assert response["success"]
      assert response["data"]["object"] == "list"
      assert is_list(response["data"]["data"])
    end

    test_with_auths "returns a list of settings" do
      response = request("/configuration.all")
      assert response["success"] == true

      assert length(response["data"]["data"]) ==
               Enum.count(Application.get_env(:ewallet_config, :default_settings))
    end
  end

  describe "/configuration.update" do
    test_with_auths "updates one setting", context do
      response =
        request("/configuration.update", %{
          base_url: "new_base_url.example",
          config_pid: context[:config_pid]
        })

      assert response["success"] == true
      assert response["data"]["data"]["base_url"] != nil
      assert response["data"]["data"]["base_url"]["value"] == "new_base_url.example"
    end

    test_with_auths "updates a list of settings", context do
      response =
        request("/configuration.update", %{
          "aws_access_key_id" => "asd",
          "aws_bucket" => "asd",
          "aws_region" => "asdz",
          "aws_secret_access_key" => "asdasdasdasdasd",
          "enable_standalone" => false,
          "config_pid" => context[:config_pid]
        })

      assert response["success"] == true
      data = response["data"]["data"]

      assert data["aws_access_key_id"]["value"] == "asd"
      assert data["aws_bucket"]["value"] == "asd"
      assert data["aws_region"]["value"] == "asdz"
      assert data["aws_secret_access_key"]["value"] == "asdasdasdasdasd"
      assert data["enable_standalone"]["value"] == false
    end

    test_with_auths "updates a list of settings with failures", context do
      response =
        request("/configuration.update", %{
          base_url: "new_base_url.example",
          redirect_url_prefixes: ["new_base_url.example", "something.else"],
          fake_setting: "my_value",
          max_per_page: true,
          email_adapter: "fake",
          enable_standalone: true,
          config_pid: context[:config_pid]
        })

      assert response["success"] == true
      data = response["data"]["data"]

      assert data["base_url"] != nil
      assert data["base_url"]["value"] == "new_base_url.example"

      assert data["enable_standalone"] != nil
      assert data["enable_standalone"]["value"] == true

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

    test_with_auths "reloads app env", context do
      response =
        request("/configuration.update", %{
          base_url: "new_base_url.example",
          config_pid: context[:config_pid]
        })

      assert response["success"] == true

      assert Application.get_env(:admin_api, :base_url, "new_base_url.example")
    end

    test_with_auths "returns unauthorized error if the admin is not from the master account",
                    context do
      auth_token = insert(:auth_token, owner_app: "admin_api")
      key = insert(:key)

      opts = [
        user_id: auth_token.user.id,
        auth_token: auth_token.token,
        access_key: key.access_key,
        secret_key: key.secret_key
      ]

      response =
        request(
          "/configuration.update",
          %{
            base_url: "new_base_url.example",
            config_pid: context[:config_pid]
          },
          opts
        )

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

    defp assert_update_logs(logs, originator, target) do
      assert Enum.count(logs) == 1

      logs
      |> Enum.at(0)
      |> assert_activity_log(
        action: "update",
        originator: originator,
        target: %StoredSetting{uuid: target.uuid},
        changes: %{"data" => %{"value" => target.value}, "position" => target.position},
        encrypted_changes: %{}
      )
    end

    test "generates an activity log for an admin request", context do
      timestamp = DateTime.utc_now()

      response =
        admin_user_request("/configuration.update", %{
          base_url: "new_base_url.example",
          config_pid: context[:config_pid]
        })

      assert response["success"] == true
      setting = Config.get_setting(:base_url)

      timestamp
      |> get_all_activity_logs_since()
      |> assert_update_logs(get_test_admin(), setting)
    end

    test "generates an activity log for a provider request", context do
      timestamp = DateTime.utc_now()

      response =
        provider_request("/configuration.update", %{
          base_url: "new_base_url.example",
          config_pid: context[:config_pid]
        })

      assert response["success"] == true
      setting = Config.get_setting(:base_url)

      timestamp
      |> get_all_activity_logs_since()
      |> assert_update_logs(get_test_key(), setting)
    end
  end
end
