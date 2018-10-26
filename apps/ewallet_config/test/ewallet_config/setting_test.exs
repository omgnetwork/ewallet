defmodule EWalletConfig.SettingTest do
  use EWalletConfig.SchemaCase
  alias EWalletConfig.{Repo, Setting, StoredSetting}

  def get_attrs do
    %{key: "my_key", value: "test", type: "string"}
  end

  describe "all/0" do
    test "returns all settings" do
      {:ok, _} = Setting.insert(%{key: "k1", value: "v", type: "string"})
      {:ok, _} = Setting.insert(%{key: "k2", value: "v", type: "string"})
      {:ok, _} = Setting.insert(%{key: "k3", value: "v", type: "string"})

      settings = Setting.all() |> Enum.map(fn s -> {s.key, s.value} end)
      assert Enum.member?(settings, {"k1", "v"})
      assert Enum.member?(settings, {"k2", "v"})
      assert Enum.member?(settings, {"k3", "v"})
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

  describe "get_value/2" do
    test "it returns the setting value" do
      {:ok, _} = Setting.insert(get_attrs())
      assert Setting.get_value("my_key") == "test"
    end

    test "it returns the setting encrypted_value" do
      {:ok, _} = Setting.insert(%{key: "my_key", value: "test", type: "string", secret: true})
      assert Setting.get_value("my_key") == "test"
    end

    test "it returns the setting default value given as param" do
      assert Setting.get_value("my_key", "something_else") == "something_else"
    end

    test "it returns nil when the given key is nil" do
      assert Setting.get_value(nil) == nil
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
      {res, setting} =
        Setting.insert(%{
          key: "my_key",
          value: "test",
          type: "string",
          description: "My Description"
        })

      assert res == :ok
      assert setting.description == "My Description"
    end

    test "inserts a setting with a position" do
      {res, setting} = Setting.insert(get_attrs())

      assert res == :ok
      assert setting.position == 0

      {res, setting} = Setting.insert(%{key: "my_key_2", value: "test", type: "string"})

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
      attrs = %{key: "my_key", value: "cool", type: "string"}
      {res, setting} = Setting.insert(attrs)

      assert res == :ok
      assert setting.uuid != nil
      assert setting.value == "cool"
    end

    test "inserts a setting with a string value and options" do
      attrs = %{key: "my_key", value: "def", type: "string", options: ["abc", "def"]}
      {res, setting} = Setting.insert(attrs)

      assert res == :ok
      assert setting.uuid != nil
      assert setting.value == "def"
    end

    test "fails to insert a setting with an invalid value and options" do
      attrs = %{key: "my_key", value: "xyz", type: "string", options: ["abc", "def"]}
      {res, changeset} = Setting.insert(attrs)

      assert res == :error

      assert changeset.errors == [
               value: {"must be one of 'abc', 'def'", [validation: :value_not_allowed]}
             ]
    end

    test "inserts a setting with an encrypted json" do
      attrs = %{key: "my_key", value: %{key: "value"}, secret: true, type: "map"}
      {:ok, setting} = Setting.insert(attrs)
      stored_setting = Repo.get_by(StoredSetting, key: "my_key")

      assert setting.secret == true
      assert Setting.get_value("my_key") == %{"key" => "value"}
      assert stored_setting.secret == true
      assert stored_setting.data == nil
      assert stored_setting.encrypted_data == %{"value" => %{"key" => "value"}}
    end

    test "inserts a setting with an integer value" do
      attrs = %{key: "my_key", value: 5, type: "integer"}
      {res, setting} = Setting.insert(attrs)

      assert res == :ok
      assert setting.uuid != nil
      assert setting.value == 5
    end

    test "inserts a setting with a map value" do
      attrs = %{key: "my_key", value: %{a: "b"}, type: "map"}
      {res, setting} = Setting.insert(attrs)

      assert res == :ok
      assert setting.uuid != nil
      assert setting.value == %{a: "b"}
    end

    test "inserts a setting with a boolean value" do
      attrs = %{key: "my_key", value: true, type: "boolean"}
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

  describe "update/2" do
    test "updates a setting" do
      {:ok, setting} = Setting.insert(get_attrs())
      {res, updated_setting} = Setting.update("my_key", %{value: "new_value"})

      assert res == :ok
      assert setting.uuid == updated_setting.uuid
      assert updated_setting.value == "new_value"

      assert NaiveDateTime.compare(
               setting.updated_at,
               updated_setting.updated_at
             ) == :lt
    end

    test "fails to update when the setting is not found" do
      {res, error} = Setting.update("fake", %{value: "new_value"})

      assert res == :error
      assert error == :setting_not_found
    end

    test "updates a select setting when the value is valid" do
      {:ok, _} =
        Setting.insert(%{
          key: "my_key",
          value: "abc",
          type: "string",
          options: ["abc", "def", "xyz"]
        })

      {res, setting} = Setting.update("my_key", %{value: "xyz"})

      assert res == :ok
      assert setting.value == "xyz"
    end

    test "fails to update a select setting when the value is invalid" do
      {:ok, _} =
        Setting.insert(%{
          key: "my_key",
          value: "abc",
          type: "string",
          options: ["abc", "def", "xyz"]
        })

      {res, changeset} = Setting.update("my_key", %{value: "something_else"})

      assert res == :error

      assert changeset.errors == [
               value: {"must be one of 'abc', 'def', 'xyz'", [validation: :value_not_allowed]}
             ]
    end

    test "fails to update a setting when the value is not of the right type (string)" do
      {:ok, _} = Setting.insert(%{key: "my_key", value: "abc", type: "string"})
      {res, changeset} = Setting.update("my_key", %{value: 123})

      assert res == :error

      assert changeset.errors == [
               value: {"must be of type 'string'", [validation: :invalid_type_for_value]}
             ]
    end

    test "fails to update a setting when the value is not of the right type (integer)" do
      {:ok, _} = Setting.insert(%{key: "my_key", value: 123, type: "integer"})
      {res, changeset} = Setting.update("my_key", %{value: "some_string"})

      assert res == :error

      assert changeset.errors == [
               value: {"must be of type 'integer'", [validation: :invalid_type_for_value]}
             ]
    end

    test "fails to update a setting when the value is not of the right type (map)" do
      {:ok, _} = Setting.insert(%{key: "my_key", value: %{key: "value"}, type: "map"})
      {res, changeset} = Setting.update("my_key", %{value: "some_string"})

      assert res == :error

      assert changeset.errors == [
               value: {"must be of type 'map'", [validation: :invalid_type_for_value]}
             ]
    end

    test "fails to update a setting when the value is not of the right type (array)" do
      {:ok, _} = Setting.insert(%{key: "my_key", value: [1, 2, 3], type: "array"})
      {res, changeset} = Setting.update("my_key", %{value: "some_string"})

      assert res == :error

      assert changeset.errors == [
               value: {"must be of type 'array'", [validation: :invalid_type_for_value]}
             ]
    end

    test "fails to update a setting when the value is not of the right type (boolean)" do
      {:ok, _} = Setting.insert(%{key: "my_key", value: true, type: "boolean"})
      {res, changeset} = Setting.update("my_key", %{value: "some_string"})

      assert res == :error

      assert changeset.errors == [
               value: {"must be of type 'boolean'", [validation: :invalid_type_for_value]}
             ]
    end
  end

  describe "updated_all/1" do
    test "updates all the given settings" do
      {:ok, _} = Setting.insert(%{key: "my_key_1", value: "test_1", type: "string"})
      {:ok, _} = Setting.insert(%{key: "my_key_2", value: "test_2", type: "string"})
      {:ok, _} = Setting.insert(%{key: "my_key_3", value: "test_3", type: "string"})

      res =
        Setting.update_all([
          %{key: "my_key_1", value: "new_value_1"},
          %{key: "my_key_3", value: "new_value_3"}
        ])

      {res1, s1} = Enum.at(res, 0)
      {res2, s2} = Enum.at(res, 1)

      assert res1 == :ok
      assert s1.value == "new_value_1"

      assert res2 == :ok
      assert s2.value == "new_value_3"
    end

    test "fails to update some of the settings" do
      {:ok, _} = Setting.insert(%{key: "my_key_1", value: "test_1", type: "string"})
      {:ok, _} = Setting.insert(%{key: "my_key_2", value: "test_2", type: "string"})
      {:ok, _} = Setting.insert(%{key: "my_key_3", value: "test_3", type: "string"})

      res =
        Setting.update_all([
          %{key: "my_key_1", value: "new_value_1"},
          %{key: "my_key_3z", value: "new_value_3"}
        ])

      {res1, s1} = Enum.at(res, 0)
      {res2, error} = Enum.at(res, 1)

      assert res1 == :ok
      assert s1.value == "new_value_1"

      assert res2 == :error
      assert error == :setting_not_found
    end
  end

  describe "insert_all_defaults/1" do
    test "insert all defaults without overrides" do
      assert Setting.insert_all_defaults() == :ok
      settings = Setting.all()

      assert length(settings) == 19

      first_setting = Enum.at(settings, 0)
      assert first_setting.key == "base_url"
    end

    test "insert all defaults with overrides" do
      assert Setting.insert_all_defaults(%{
               "base_url" => "fake_url"
             }) == :ok

      assert length(Setting.all()) == 19
      assert Setting.get_value("base_url") == "fake_url"
    end
  end
end
