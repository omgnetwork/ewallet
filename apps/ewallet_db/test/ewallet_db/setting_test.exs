defmodule EWalletDB.SettingTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.Setting

  def get_attrs do
    %{key: "my_key", value: "test", type: "string"}
  end

  describe "all/0" do
    test "returns all settings" do
      {:ok, _} = Setting.insert(%{key: "k1", value: "v", type: "string"})
      {:ok, _} = Setting.insert(%{key: "k2", value: "v", type: "string"})
      {:ok, _} = Setting.insert(%{key: "k3", value: "v", type: "string"})
    end
  end

  describe "get/1" do
    test "returns nil when given nil" do
      assert Setting.get(nil) == nil
    end

    test "returns the setting" do
      {:ok, inserted_setting} = Setting.insert(get_attrs())
      setting = Setting.get("my_key")

      assert inserted_setting.uuid == setting.uuid
    end
  end

  describe "insert/1" do
    test "inserts a setting with a UUID" do
      {res, setting} = Setting.insert(get_attrs())

      assert res == :ok
      assert setting.uuid != nil
    end

    test "inserts a setting with an ID" do
      {res, setting} = Setting.insert(get_attrs())

      assert res == :ok
      assert String.starts_with?(setting.id, "stg_")
      assert String.length(setting.id) == String.length("stg_") + 26
    end

    test "inserts a setting with a description" do
      {res, setting} = Setting.insert(%{key: "my_key", value: "test", type: "string", description: "My Description"})

      assert res == :ok
      assert setting.description == "My Description"
    end

    test "inserts a setting with a position" do
      {res, setting} = Setting.insert(get_attrs())

      assert res == :ok
      assert setting.position == 0

      {res, setting} = Setting.insert(%{key: "my_key_2", value: "test", type: "array"})

      assert res == :ok
      assert setting.position == 1
    end

    test "inserts with timestamps" do
      {res, setting} = Setting.insert(get_attrs())

      assert res == :ok
      assert setting.inserted_at != nil
      assert setting.updated_at != nil
    end

    test "inserts a setting with an array value" do
      attrs = %{key: "array_key", value: ["a", "b", "c"], type: "array"}
      {res, setting} = Setting.insert(attrs)

      assert res == :ok
      assert setting.uuid != nil
      assert setting.value == ["a", "b", "c"]
    end

    test "inserts a CRON schedule" do
      {res, setting} =
        Setting.insert(%{key: "balance_caching_schedule", value: "* * * * *", type: "string"})

      assert res == :ok
      assert setting.key == "balance_caching_schedule"
      assert setting.value == "* * * * *"
    end

    test "inserts a setting with a string value" do
      attrs = %{key: "my_key", value: "cool", type: "array"}
      {res, setting} = Setting.insert(attrs)

      assert res == :ok
      assert setting.uuid != nil
      assert setting.value == "cool"
    end

    test "inserts a setting with an integer value" do
      attrs = %{key: "my_key", value: 5, type: "array"}
      {res, setting} = Setting.insert(attrs)

      assert res == :ok
      assert setting.uuid != nil
      assert setting.value == 5
    end

    test "inserts a setting with a map value" do
      attrs = %{key: "my_key", value: %{a: "b"}, type: "array"}
      {res, setting} = Setting.insert(attrs)

      assert res == :ok
      assert setting.uuid != nil
      assert setting.value == %{a: "b"}
    end

    test "inserts a setting with a boolean value" do
      attrs = %{key: "my_key", value: true, type: "array"}
      {res, setting} = Setting.insert(attrs)

      assert res == :ok
      assert setting.uuid != nil
      assert setting.value == true
    end

    test "inserts when value is nil" do
      attrs = %{key: "my_key", type: "string"}
      {res, setting} = Setting.insert(attrs)

      assert res == :ok
      assert setting.uuid != nil
      assert setting.value == nil
    end

    test "fails to insert when key is not present" do
      attrs = %{value: "abc", type: "string"}
      {res, changeset} = Setting.insert(attrs)

      assert res == :error
      assert changeset.changes == %{
        type: "string",
        value: "abc",
        position: 0
      }
      assert changeset.errors == [key: {"can't be blank", [validation: :required]}]
    end

    test "fails to insert when type is not valid" do
      attrs = %{key: "my_key", value: true, type: "fake"}
      {res, changeset} = Setting.insert(attrs)

      assert res == :error
      assert changeset.changes == %{
        key: "my_key",
        type: "fake",
        value: true,
        position: 0
      }
      assert changeset.errors == [type: {"is invalid", [validation: :inclusion]}]
      assert changeset.valid? == false
      assert changeset.action == :insert
      assert changeset.data == %Setting{}
    end
  end
end
