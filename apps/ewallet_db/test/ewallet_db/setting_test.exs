defmodule EWalletDB.SettingTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.Setting

  describe "Setting factory" do
    test_has_valid_factory(Setting)
  end

  describe "insert/1" do
    test_insert_generate_uuid(Setting, :uuid)
    test_insert_generate_external_id(Setting, :id, "stg_")
    test_insert_generate_timestamps(Setting)
    test_insert_prevent_blank(Setting, :key)
  end

  describe "get/1" do
    test "returns nil when given nil" do
      assert Setting.get(nil) == nil
    end

    test "returns the setting" do
      inserted_setting = insert(:setting, key: "my_setting")
      setting = Setting.get("my_setting")

      assert inserted_setting.uuid == setting.uuid
    end
  end
end
