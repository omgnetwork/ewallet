defmodule EWalletConfig.SettingLoaderTest do
  use EWalletConfig.SchemaCase, async: true
  alias EWalletConfig.{Config, SettingLoader}
  alias ActivityLogger.System

  describe "load_settings/2" do
    test "loads the settings" do
      {:ok, _} =
        Config.insert(%{
          key: "my_setting_1",
          value: "value_1",
          type: "string",
          originator: %System{}
        })

      {:ok, _} =
        Config.insert(%{
          key: "my_setting_2",
          value: "value_2",
          type: "string",
          originator: %System{}
        })

      SettingLoader.load_settings(:my_app, [:my_setting_1, :my_setting_2])

      assert Application.get_env(:my_app, :my_setting_1) == "value_1"
      assert Application.get_env(:my_app, :my_setting_2) == "value_2"
    end
  end

  describe "load_setting/2" do
    test "sets nil when the setting doesn't exist" do
      SettingLoader.load_settings(:my_app, [:my_setting_1])
      assert Application.get_env(:my_app, :my_setting_1) == nil
    end

    test "load one setting when not secret" do
      {:ok, _} =
        Config.insert(%{key: "my_setting", value: "value", type: "string", originator: %System{}})

      SettingLoader.load_settings(:my_app, [:my_setting])

      assert Application.get_env(:my_app, :my_setting) == "value"
    end

    test "load one setting when secret" do
      {:ok, _} =
        Config.insert(%{
          key: "my_setting",
          value: "value",
          secret: true,
          type: "string",
          originator: %System{}
        })

      SettingLoader.load_settings(:my_app, [:my_setting])

      assert Application.get_env(:my_app, :my_setting) == "value"
    end

    test "load key with mapped name" do
      {:ok, _} =
        Config.insert(%{
          key: "email_adapter",
          value: "smtp",
          type: "string",
          originator: %System{}
        })

      SettingLoader.load_settings(:my_app, [:email_adapter])

      assert Application.get_env(:my_app, :email_adapter) == Bamboo.SMTPAdapter
    end
  end
end
