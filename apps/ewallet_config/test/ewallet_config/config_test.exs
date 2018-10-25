defmodule EWalletConfig.ConfigTest do
  use EWalletConfig.SchemaCase, async: true
  alias EWalletConfig.{Config, Repo, Setting}
  alias Ecto.Adapters.SQL.Sandbox

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
      {:ok, pid} = Config.start_link()
      Sandbox.allow(Repo, self(), pid)
      {:ok, _} = Config.insert(%{key: "my_setting", value: "some_value", type: "string"})

      assert Config.register_and_load(:my_app, [:my_setting], pid) == :ok
      assert Enum.member?(Config.get_registered_apps(pid), {:my_app, [:my_setting]})
      assert Application.get_env(:my_app, :my_setting) == "some_value"
    end
  end

  describe "reload_config/1" do
    test "reloads all settings" do
      {:ok, pid} = Config.start_link()
      Sandbox.allow(Repo, self(), pid)
      {:ok, _} = Config.insert(%{key: "my_setting", value: "some_value", type: "string"})

      assert Config.register_and_load(:my_app, [:my_setting], pid) == :ok
      assert Application.get_env(:my_app, :my_setting) == "some_value"

      {:ok, _} = Setting.update("my_setting", %{value: "new_value"})
      assert Application.get_env(:my_app, :my_setting) == "some_value"

      :ok = Config.reload_config(pid)
      assert Application.get_env(:my_app, :my_setting) == "new_value"
    end
  end

  describe "update/3" do
    test "updates a setting and reload" do
      {:ok, pid} = Config.start_link()
      Sandbox.allow(Repo, self(), pid)
      {:ok, _} = Config.insert(%{key: "my_setting", value: "some_value", type: "string"})
      assert Config.register_and_load(:my_app, [:my_setting], pid) == :ok
      assert Application.get_env(:my_app, :my_setting) == "some_value"

      {:ok, _} = Config.update("my_setting", %{value: "new_value"}, pid)
      assert Application.get_env(:my_app, :my_setting) == "new_value"
    end
  end

  describe "update_all/3" do
    test "updates all settings and reload" do
      {:ok, pid} = Config.start_link()
      Sandbox.allow(Repo, self(), pid)
      {:ok, _} = Config.insert(%{key: "my_setting", value: "some_value", type: "string"})
      assert Config.register_and_load(:my_app, [:my_setting], pid) == :ok
      assert Application.get_env(:my_app, :my_setting) == "some_value"

      res = Config.update_all([%{key: "my_setting", value: "new_value"}], pid)
      assert {:ok, _} = Enum.at(res, 0)
      assert Application.get_env(:my_app, :my_setting) == "new_value"
    end
  end

  describe "insert_all_defaults/2" do
    test "insert all default settings" do
      {:ok, pid} = Config.start_link()
      Sandbox.allow(Repo, self(), pid)
      :ok = Config.insert_all_defaults(%{}, pid)

      assert length(Config.settings()) == 19
    end
  end

  describe "settings/0" do
    test "gets all the settings" do
      {:ok, pid} = Config.start_link()
      Sandbox.allow(Repo, self(), pid)
      {:ok, _} = Config.insert(%{key: "my_setting", value: "some_value", type: "string"})

      assert length(Config.settings()) == 1
    end
  end

  describe "get/2" do
    test "gets a setting by key" do
      {:ok, pid} = Config.start_link()
      Sandbox.allow(Repo, self(), pid)
      {:ok, _} = Config.insert(%{key: "my_setting", value: "some_value", type: "string"})

      value = Config.get("my_setting")
      assert value == "some_value"
    end

    test "returns the default value when setting value is nil" do
      {:ok, pid} = Config.start_link()
      Sandbox.allow(Repo, self(), pid)
      {:ok, _} = Config.insert(%{key: "my_setting", value: nil, type: "string"})

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
