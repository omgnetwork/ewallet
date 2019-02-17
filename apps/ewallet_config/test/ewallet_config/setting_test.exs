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

defmodule EWalletConfig.SettingTest do
  use EWalletConfig.SchemaCase, async: true
  alias EWalletConfig.{Repo, Setting, StoredSetting}
  alias ActivityLogger.System

  def get_attrs do
    %{key: "my_key", value: "test", type: "string", originator: %System{}}
  end

  describe "all/0" do
    test "returns all settings" do
      {:ok, _} = Setting.insert(%{key: "k1", value: "v", type: "string", originator: %System{}})
      {:ok, _} = Setting.insert(%{key: "k2", value: "v", type: "string", originator: %System{}})
      {:ok, _} = Setting.insert(%{key: "k3", value: "v", type: "string", originator: %System{}})

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
      {:ok, _} =
        Setting.insert(%{
          key: "my_key",
          value: "test",
          type: "string",
          secret: true,
          originator: %System{}
        })

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
          description: "My Description",
          originator: %System{}
        })

      assert res == :ok
      assert setting.description == "My Description"
    end

    test "inserts a setting with a position" do
      {res, setting} = Setting.insert(get_attrs())

      assert res == :ok
      assert setting.position == 0

      {res, setting} =
        Setting.insert(%{key: "my_key_2", value: "test", type: "string", originator: %System{}})

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
      attrs = %{key: "array_key", value: ["a", "b", "c"], type: "array", originator: %System{}}
      {res, setting} = Setting.insert(attrs)

      assert res == :ok
      assert setting.uuid != nil
      assert setting.value == ["a", "b", "c"]
    end

    test "inserts a CRON schedule" do
      {res, setting} =
        Setting.insert(%{
          key: "balance_caching_schedule",
          value: "* * * * *",
          type: "string",
          originator: %System{}
        })

      assert res == :ok
      assert setting.key == "balance_caching_schedule"
      assert setting.value == "* * * * *"
    end

    test "inserts a setting with a string value" do
      attrs = %{key: "my_key", value: "cool", type: "string", originator: %System{}}
      {res, setting} = Setting.insert(attrs)

      assert res == :ok
      assert setting.uuid != nil
      assert setting.value == "cool"
    end

    test "inserts a setting with a string value and options" do
      attrs = %{
        key: "my_key",
        value: "def",
        type: "string",
        options: ["abc", "def"],
        originator: %System{}
      }

      {res, setting} = Setting.insert(attrs)

      assert res == :ok
      assert setting.uuid != nil
      assert setting.value == "def"
    end

    test "fails to insert a setting with an invalid value and options" do
      attrs = %{
        key: "my_key",
        value: "xyz",
        type: "string",
        options: ["abc", "def"],
        originator: %System{}
      }

      {res, changeset} = Setting.insert(attrs)

      assert res == :error

      assert changeset.errors == [
               value: {"must be one of 'abc', 'def'", [validation: :value_not_allowed]}
             ]
    end

    test "inserts a setting with an encrypted json" do
      attrs = %{
        key: "my_key",
        value: %{key: "value"},
        secret: true,
        type: "map",
        originator: %System{}
      }

      {:ok, setting} = Setting.insert(attrs)
      stored_setting = Repo.get_by(StoredSetting, key: "my_key")

      assert setting.secret == true
      assert Setting.get_value("my_key") == %{"key" => "value"}
      assert stored_setting.secret == true
      assert stored_setting.data == nil
      assert stored_setting.encrypted_data == %{"value" => %{"key" => "value"}}
    end

    test "inserts a setting with an integer value" do
      attrs = %{key: "my_key", value: 5, type: "integer", originator: %System{}}
      {res, setting} = Setting.insert(attrs)

      assert res == :ok
      assert setting.uuid != nil
      assert setting.value == 5
    end

    test "inserts a setting with a map value" do
      attrs = %{key: "my_key", value: %{a: "b"}, type: "map", originator: %System{}}
      {res, setting} = Setting.insert(attrs)

      assert res == :ok
      assert setting.uuid != nil
      assert setting.value == %{a: "b"}
    end

    test "inserts a setting with a boolean value" do
      attrs = %{key: "my_key", value: true, type: "boolean", originator: %System{}}
      {res, setting} = Setting.insert(attrs)

      assert res == :ok
      assert setting.uuid != nil
      assert setting.value == true
    end

    test "inserts when value is nil" do
      attrs = %{key: "my_key", type: "string", originator: %System{}}
      {res, setting} = Setting.insert(attrs)

      assert res == :ok
      assert setting.uuid != nil
      assert setting.value == nil
    end

    test "fails to insert when key is not present" do
      attrs = %{value: "abc", type: "string", originator: %System{}}
      {res, changeset} = Setting.insert(attrs)

      assert res == :error

      assert changeset.changes == %{
               type: "string",
               data: %{value: "abc"},
               position: 0,
               originator: %ActivityLogger.System{uuid: "00000000-0000-0000-0000-000000000000"},
               prevent_saving: [],
               encrypted_changes: %{},
               encrypted_fields: [:encrypted_data]
             }

      assert changeset.errors == [key: {"can't be blank", [validation: :required]}]
    end

    test "fails to insert when type is not valid" do
      attrs = %{key: "my_key", value: true, type: "fake", originator: %System{}}
      {res, changeset} = Setting.insert(attrs)

      assert res == :error

      assert changeset.changes == %{
               key: "my_key",
               type: "fake",
               data: %{value: true},
               position: 0,
               originator: %ActivityLogger.System{uuid: "00000000-0000-0000-0000-000000000000"},
               prevent_saving: [],
               encrypted_changes: %{},
               encrypted_fields: [:encrypted_data]
             }

      assert changeset.errors == [type: {"is invalid", [validation: :inclusion]}]
      assert changeset.valid? == false
      assert changeset.action == :insert
      assert %StoredSetting{} = changeset.data
    end
  end

  describe "update/2" do
    test "updates a setting" do
      {:ok, setting} = Setting.insert(get_attrs())

      {res, updated_setting} =
        Setting.update("my_key", %{value: "new_value", originator: %System{}})

      assert res == :ok
      assert setting.uuid == updated_setting.uuid
      assert updated_setting.value == "new_value"

      assert NaiveDateTime.compare(
               setting.updated_at,
               updated_setting.updated_at
             ) == :lt
    end

    test "fails to update when the setting is not found" do
      {res, error} = Setting.update("fake", %{value: "new_value", originator: %System{}})

      assert res == :error
      assert error == :setting_not_found
    end

    test "updates a select setting when the value is valid" do
      {:ok, _} =
        Setting.insert(%{
          key: "my_key",
          value: "abc",
          type: "string",
          options: ["abc", "def", "xyz"],
          originator: %System{}
        })

      {res, setting} = Setting.update("my_key", %{value: "xyz", originator: %System{}})

      assert res == :ok
      assert setting.value == "xyz"
    end

    test "updates only the position and leave the value unchanged" do
      {:ok, _} =
        Setting.insert(%{
          key: "my_key",
          value: "abc",
          type: "string",
          position: 1,
          originator: %System{}
        })

      {res, setting} = Setting.update("my_key", %{position: 2, originator: %System{}})

      assert res == :ok
      assert setting.value == "abc"
      assert setting.position == 2
    end

    test "can update a value to nil" do
      {:ok, _} =
        Setting.insert(%{
          key: "my_key",
          value: "abc",
          type: "string",
          originator: %System{}
        })

      {res, setting} = Setting.update("my_key", %{value: nil, originator: %System{}})

      assert res == :ok
      assert setting.value == nil
    end

    test "fails to update a select setting when the value is invalid" do
      {:ok, _} =
        Setting.insert(%{
          key: "my_key",
          value: "abc",
          type: "string",
          options: ["abc", "def", "xyz"],
          originator: %System{}
        })

      {res, changeset} =
        Setting.update("my_key", %{value: "something_else", originator: %System{}})

      assert res == :error

      assert changeset.errors == [
               value: {"must be one of 'abc', 'def', 'xyz'", [validation: :value_not_allowed]}
             ]
    end

    test "fails to update a setting when the value is not of the right type (string)" do
      {:ok, _} =
        Setting.insert(%{key: "my_key", value: "abc", type: "string", originator: %System{}})

      {res, changeset} = Setting.update("my_key", %{value: 123, originator: %System{}})

      assert res == :error

      assert changeset.errors == [
               value: {"must be of type 'string'", [validation: :invalid_type_for_value]}
             ]
    end

    test "fails to update a setting when the value is not of the right type (integer)" do
      {:ok, _} =
        Setting.insert(%{key: "my_key", value: 123, type: "integer", originator: %System{}})

      {res, changeset} = Setting.update("my_key", %{value: "some_string", originator: %System{}})

      assert res == :error

      assert changeset.errors == [
               value: {"must be of type 'integer'", [validation: :invalid_type_for_value]}
             ]
    end

    test "fails to update a setting when the value is not of the right type (map)" do
      {:ok, _} =
        Setting.insert(%{
          key: "my_key",
          value: %{key: "value"},
          type: "map",
          originator: %System{}
        })

      {res, changeset} = Setting.update("my_key", %{value: "some_string", originator: %System{}})

      assert res == :error

      assert changeset.errors == [
               value: {"must be of type 'map'", [validation: :invalid_type_for_value]}
             ]
    end

    test "fails to update a setting when the value is not of the right type (array)" do
      {:ok, _} =
        Setting.insert(%{key: "my_key", value: [1, 2, 3], type: "array", originator: %System{}})

      {res, changeset} = Setting.update("my_key", %{value: "some_string", originator: %System{}})

      assert res == :error

      assert changeset.errors == [
               value: {"must be of type 'array'", [validation: :invalid_type_for_value]}
             ]
    end

    test "fails to update a setting when the value is not of the right type (boolean)" do
      {:ok, _} =
        Setting.insert(%{key: "my_key", value: true, type: "boolean", originator: %System{}})

      {res, changeset} = Setting.update("my_key", %{value: "some_string", originator: %System{}})

      assert res == :error

      assert changeset.errors == [
               value: {"must be of type 'boolean'", [validation: :invalid_type_for_value]}
             ]
    end
  end

  describe "updated_all/1" do
    test "updates all the given settings with list" do
      {:ok, _} =
        Setting.insert(%{key: "my_key_1", value: "test_1", type: "string", originator: %System{}})

      {:ok, _} =
        Setting.insert(%{key: "my_key_2", value: "test_2", type: "string", originator: %System{}})

      {:ok, _} =
        Setting.insert(%{key: "my_key_3", value: "test_3", type: "string", originator: %System{}})

      res =
        Setting.update_all([
          %{key: "my_key_1", value: "new_value_1", originator: %System{}},
          %{key: "my_key_3", value: "new_value_3", originator: %System{}}
        ])

      {_key1, {res1, s1}} = Enum.at(res, 0)
      {_key2, {res2, s2}} = Enum.at(res, 1)

      assert res1 == :ok
      assert s1.value == "new_value_1"

      assert res2 == :ok
      assert s2.value == "new_value_3"
    end

    test "updates all the given settings with map" do
      {:ok, _} =
        Setting.insert(%{key: "my_key_1", value: "test_1", type: "string", originator: %System{}})

      {:ok, _} =
        Setting.insert(%{key: "my_key_2", value: "test_2", type: "string", originator: %System{}})

      {:ok, _} =
        Setting.insert(%{key: "my_key_3", value: "test_3", type: "string", originator: %System{}})

      res =
        Setting.update_all(%{
          my_key_1: "new_value_1",
          my_key_3: "new_value_3",
          originator: %System{}
        })

      {_key1, {res1, s1}} = Enum.at(res, 0)
      {_key2, {res2, s2}} = Enum.at(res, 1)

      assert res1 == :ok
      assert s1.value == "new_value_1"

      assert res2 == :ok
      assert s2.value == "new_value_3"
    end

    test "updates all the given settings with keyword list" do
      {:ok, _} =
        Setting.insert(%{key: "my_key_1", value: "test_1", type: "string", originator: %System{}})

      {:ok, _} =
        Setting.insert(%{key: "my_key_2", value: "test_2", type: "string", originator: %System{}})

      {:ok, _} =
        Setting.insert(%{key: "my_key_3", value: "test_3", type: "string", originator: %System{}})

      res =
        Setting.update_all(
          my_key_1: "new_value_1",
          my_key_3: "new_value_3",
          originator: %System{}
        )

      {_key1, {res1, s1}} = Enum.at(res, 0)
      {_key2, {res2, s2}} = Enum.at(res, 1)

      assert res1 == :ok
      assert s1.value == "new_value_1"

      assert res2 == :ok
      assert s2.value == "new_value_3"
    end

    test "fails to update some of the settings" do
      {:ok, _} =
        Setting.insert(%{key: "my_key_1", value: "test_1", type: "string", originator: %System{}})

      {:ok, _} =
        Setting.insert(%{key: "my_key_2", value: "test_2", type: "string", originator: %System{}})

      {:ok, _} =
        Setting.insert(%{key: "my_key_3", value: "test_3", type: "string", originator: %System{}})

      res =
        Setting.update_all([
          %{key: "my_key_1", value: "new_value_1", originator: %System{}},
          %{key: "my_key_3z", value: "new_value_3", originator: %System{}}
        ])

      {_key1, {res1, s1}} = Enum.at(res, 0)
      {_key2, {res2, s2}} = Enum.at(res, 1)

      assert res1 == :ok
      assert s1.value == "new_value_1"

      assert res2 == :error
      assert s2 == :setting_not_found
    end
  end

  describe "insert_all_defaults/1" do
    test "insert all defaults without overrides" do
      assert Setting.insert_all_defaults(%System{}) == :ok
      default_settings = Application.get_env(:ewallet_config, :default_settings)
      settings = Setting.all()

      assert length(settings) == Enum.count(default_settings)

      first_setting = Enum.at(settings, 0)
      assert first_setting.key == "base_url"
    end

    test "insert all defaults with overrides" do
      assert Setting.insert_all_defaults(%System{}, %{
               "base_url" => "fake_url"
             }) == :ok

      default_settings = Application.get_env(:ewallet_config, :default_settings)

      assert length(Setting.all()) == Enum.count(default_settings)
      assert Setting.get_value("base_url") == "fake_url"
    end
  end
end
