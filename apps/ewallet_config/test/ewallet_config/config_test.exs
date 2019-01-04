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

defmodule EWalletConfig.ConfigTest do
  use EWalletConfig.SchemaCase, async: true
  alias EWalletConfig.{Config, Repo, Setting}
  alias Ecto.Adapters.SQL.Sandbox
  alias ActivityLogger.System

  def default_loading do
    {:ok, pid} = Config.start_link()
    Sandbox.allow(Repo, self(), pid)
    Sandbox.allow(ActivityLogger.Repo, self(), pid)

    {:ok, _} =
      Config.insert(%{
        key: "my_setting",
        value: "some_value",
        type: "string",
        originator: %System{}
      })

    assert Config.register_and_load(:my_app, [:my_setting], pid) == :ok
    assert Application.get_env(:my_app, :my_setting) == "some_value"

    pid
  end

  defp start_task(pid, callback, value, event) do
    {:ok, pid} =
      Task.start_link(fn ->
        Sandbox.allow(Repo, pid, self())
        Sandbox.allow(ActivityLogger.Repo, self(), pid)

        assert_receive :select_for_update, 5000
        _res = callback.(value)

        send(pid, event)
      end)

    pid
  end

  describe "start_link/0" do
    test "starts a new GenServer config" do
      {res, _pid} = Config.start_link()
      assert res == :ok
    end
  end

  describe "stop/1" do
    test "stops a GenServer config" do
      {:ok, pid} = Config.start_link()
      assert Config.stop(pid) == :ok
    end
  end

  describe "register_and_load/3" do
    test "handles the registration of an app" do
      pid = default_loading()

      assert Config.register_and_load(:my_app, [:my_setting], pid) == :ok
      assert Enum.member?(Config.get_registered_apps(pid), {:my_app, [:my_setting]})
      assert Application.get_env(:my_app, :my_setting) == "some_value"
    end
  end

  describe "reload_config/1" do
    test "reloads all settings" do
      pid = default_loading()

      assert Config.register_and_load(:my_app, [:my_setting], pid) == :ok
      assert Application.get_env(:my_app, :my_setting) == "some_value"

      {:ok, _} = Setting.update("my_setting", %{value: "new_value", originator: %System{}})
      assert Application.get_env(:my_app, :my_setting) == "some_value"

      :ok = Config.reload_config(pid)
      assert Application.get_env(:my_app, :my_setting) == "new_value"
    end
  end

  describe "update/3" do
    test "updates all settings and reload" do
      pid = default_loading()
      {:ok, settings} = Config.update([my_setting: "new_value", originator: %System{}], pid)

      assert {_key, {:ok, _}} = Enum.at(settings, 0)
      assert Application.get_env(:my_app, :my_setting) == "new_value"
    end

    test "updates all settings and reload with multiple sources" do
      pid = self()

      {:ok, config_pid} = Config.start_link()
      Sandbox.allow(Repo, self(), config_pid)

      {:ok, _} =
        Config.insert(%{
          key: "my_setting",
          value: "value_0",
          type: "string",
          originator: %System{}
        })

      assert Config.register_and_load(:my_app, [:my_setting], config_pid) == :ok
      assert Application.get_env(:my_app, :my_setting) == "value_0"

      callback = fn value ->
        Process.sleep(:rand.uniform(520))
        Config.update(%{my_setting: value}, config_pid)
      end

      task1 = start_task(pid, callback, "value_1", :task1)
      task2 = start_task(pid, callback, "value_2", :task2)
      task3 = start_task(pid, callback, "value_3", :task3)

      send(task1, :select_for_update)
      send(task2, :select_for_update)
      send(task3, :select_for_update)

      assert_receive :task1, 5000
      assert_receive :task2, 5000
      assert_receive :task3, 5000

      assert Config.get(:my_setting) == Application.get_env(:my_app, :my_setting)
    end

    test "removes 'config_pid' from the attrs keyword list" do
      pid = default_loading()

      assert Config.update(
               my_fake_setting: true,
               config_pid: pid
             ) ==
               {:ok,
                [
                  my_fake_setting: {:error, :setting_not_found}
                ]}
    end

    test "removes 'config_pid' from the attrs string map" do
      pid = default_loading()

      assert Config.update(%{
               "my_fake_setting" => true,
               "config_pid" => pid
             }) ==
               {:ok,
                [
                  {
                    "my_fake_setting",
                    {:error, :setting_not_found}
                  }
                ]}
    end

    test "removes 'config_pid' from the attrs atom map" do
      pid = default_loading()

      assert Config.update(%{
               my_fake_setting: true,
               config_pid: pid
             }) ==
               {:ok,
                [
                  my_fake_setting: {:error, :setting_not_found}
                ]}
    end
  end

  describe "insert_all_defaults/2" do
    test "insert all default settings" do
      {:ok, pid} = Config.start_link()
      Sandbox.allow(Repo, self(), pid)
      :ok = Config.insert_all_defaults(%System{}, %{}, pid)

      default_settings = Application.get_env(:ewallet_config, :default_settings)
      assert length(Config.settings()) == Enum.count(default_settings)
    end
  end

  describe "settings/0" do
    test "gets all the settings" do
      {:ok, pid} = Config.start_link()
      Sandbox.allow(Repo, self(), pid)

      {:ok, _} =
        Config.insert(%{
          key: "my_setting",
          value: "some_value",
          type: "string",
          originator: %System{}
        })

      assert length(Config.settings()) == 1
    end
  end

  describe "get/2" do
    test "gets a setting by key" do
      {:ok, pid} = Config.start_link()
      Sandbox.allow(Repo, self(), pid)

      {:ok, _} =
        Config.insert(%{
          key: "my_setting",
          value: "some_value",
          type: "string",
          originator: %System{}
        })

      value = Config.get("my_setting")
      assert value == "some_value"
    end

    test "returns the default value when setting value is nil" do
      {:ok, pid} = Config.start_link()
      Sandbox.allow(Repo, self(), pid)

      {:ok, _} =
        Config.insert(%{key: "my_setting", value: nil, type: "string", originator: %System{}})

      value = Config.get("my_setting", "default_value")
      assert value == "default_value"
    end

    test "returns the default value when setting does not exist" do
      {:ok, pid} = Config.start_link()
      Sandbox.allow(Repo, self(), pid)

      value = Config.get("my_setting", "default_value")
      assert value == "default_value"
    end
  end

  describe "get_boolean/2" do
    test "returns true when value is true" do
      Application.put_env(:ewallet, :config_true_boolean, true)
      assert Config.get_boolean(:ewallet, :config_true_boolean) == true
    end

    test "returns true when value is \"true\"" do
      Application.put_env(:ewallet, :config_true_string, "true")
      assert Config.get_boolean(:ewallet, :config_true_string) == true
    end

    test "returns true when value is 1" do
      Application.put_env(:ewallet, :config_one_integer, 1)
      assert Config.get_boolean(:ewallet, :config_one_integer) == true
    end

    test "returns true when value is \"1\"" do
      Application.put_env(:ewallet, :config_one_string, "1")
      assert Config.get_boolean(:ewallet, :config_one_string) == true
    end

    test "returns false when value is false" do
      Application.put_env(:ewallet, :config_false_boolean, false)
      assert Config.get_boolean(:ewallet, :config_false_boolean) == false
    end

    test "returns false when value is \"false\"" do
      Application.put_env(:ewallet, :config_false_string, "false")
      assert Config.get_boolean(:ewallet, :config_false_string) == false
    end

    test "returns false when value is 0" do
      Application.put_env(:ewallet, :config_zero_integer, 0)
      assert Config.get_boolean(:ewallet, :config_zero_integer) == false
    end

    test "returns false when value is \"0\"" do
      Application.put_env(:ewallet, :config_zero_string, "0")
      assert Config.get_boolean(:ewallet, :config_zero_string) == false
    end

    test "returns false when value is a empty string" do
      Application.put_env(:ewallet, :config_empty_string, "0")
      assert Config.get_boolean(:ewallet, :config_empty_string) == false
    end

    test "returns false when value is nil" do
      Application.put_env(:ewallet, :config_nil, nil)
      assert Config.get_boolean(:ewallet, :config_nil) == false
    end
  end

  describe "get_string/2" do
    test "returns a string" do
      Application.put_env(:ewallet, :test_get_string, "some_string")
      assert Config.get_string(:ewallet, :test_get_string) == "some_string"
    end

    test "returns nil if the key could not be found" do
      assert Config.get_string(:ewallet, :test_get_string_not_exists) == nil
    end
  end

  describe "get_strings/2" do
    test "returns a list of strings" do
      Application.put_env(:ewallet, :test_get_strings, "one,two,three")
      assert Config.get_strings(:ewallet, :test_get_strings) == ["one", "two", "three"]
    end

    test "returns the strings trimmed" do
      Application.put_env(:ewallet, :test_get_strings, "   one ,   two ,three    ")
      assert Config.get_strings(:ewallet, :test_get_strings) == ["one", "two", "three"]
    end

    test "returns without empty strings" do
      Application.put_env(:ewallet, :config_get_strings, "one, two, , three,,,")
      assert Config.get_strings(:ewallet, :config_get_strings) == ["one", "two", "three"]
    end

    test "returns an empty list if the config is nil" do
      Application.put_env(:ewallet, :test_get_strings, nil)
      assert Config.get_strings(:ewallet, :test_get_strings) == []
    end

    test "returns an empty list if the config is a blank string" do
      Application.put_env(:ewallet, :test_get_strings, "")
      assert Config.get_strings(:ewallet, :test_get_strings) == []
    end

    test "returns an empty list if all strings are trimmable" do
      Application.put_env(:ewallet, :test_get_strings, ",   , ,   , , ,,,")
      assert Config.get_strings(:ewallet, :test_get_strings) == []
    end
  end
end
