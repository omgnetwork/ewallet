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

defmodule EWalletConfig.StoredSettingTest do
  use EWalletConfig.SchemaCase
  alias ActivityLogger.System
  alias EWalletConfig.StoredSetting

  describe "changeset/2" do
    setup do
      attrs = %{
        "key" => "some_key",
        "data" => %{
          value: "some_data_value"
        },
        "type" => "string",
        "description" => "some description",
        "options" => nil,
        "parent" => nil,
        "parent_value" => nil,
        "secret" => false,
        "position" => 10,
        "originator" => %System{}
      }

      %{attrs: attrs}
    end

    test "returns a valid changeset", context do
      record = %StoredSetting{}
      changeset = StoredSetting.changeset(record, context.attrs)
      assert changeset.valid?
    end

    test "returns an invalid changeset if the `key` is being changed", context do
      record = %StoredSetting{key: "record_key"}
      changeset = StoredSetting.changeset(record, context.attrs)

      refute changeset.valid?
      assert changeset.errors == [key: {"can't be changed", []}]
    end

    test "returns an invalid changeset if the given `type` is not recognized", context do
      record = %StoredSetting{}
      attrs = Map.put(context.attrs, "type", "unknown_type")
      changeset = StoredSetting.changeset(record, attrs)

      refute changeset.valid?
      assert changeset.errors == [type: {"is invalid", [validation: :inclusion]}]
    end

    test "returns an invalid changeset if both `data` and `encrypted_data` are given", context do
      record = %StoredSetting{}
      attrs = Map.put(context.attrs, "encrypted_data", %{})
      changeset = StoredSetting.changeset(record, attrs)

      refute changeset.valid?

      assert changeset.errors == [
               {[:data, :encrypted_data],
                {"only one must be present", [validation: :only_one_required]}}
             ]
    end

    test "returns an invalid changeset if the `value` is invalid for the given `type`", context do
      record = %StoredSetting{}

      attrs =
        context.attrs
        |> Map.put("type", "integer")
        |> Map.put("data", %{value: "not_an_integer"})

      changeset = StoredSetting.changeset(record, attrs)

      refute changeset.valid?

      assert changeset.errors == [
               value: {"must be of type 'integer'", [validation: :invalid_type_for_value]}
             ]
    end

    test "returns an invalid changeset if the `value` is not in the `options`", context do
      record = %StoredSetting{}

      attrs =
        context.attrs
        |> Map.put("options", %{"array" => ["one", "two", "three"]})
        |> Map.put("data", %{value: "four"})

      changeset = StoredSetting.changeset(record, attrs)

      refute changeset.valid?

      assert changeset.errors == [
               value: {"must be one of 'one', 'two', 'three'", [validation: :value_not_allowed]}
             ]
    end
  end

  describe "update_changeset/2" do
    setup do
      record = %StoredSetting{
        key: "some_key",
        data: %{
          value: "one"
        },
        type: "string",
        description: "some description",
        options: %{
          array: ["one", "two", "three"]
        },
        parent: nil,
        parent_value: nil,
        secret: false,
        position: 10,
        originator: %System{}
      }

      %{record: record}
    end

    test "returns a valid changeset", context do
      attrs = %{
        "data" => %{
          value: "two"
        },
        "description" => "some changed description",
        "position" => 9999,
        "originator" => %System{}
      }

      changeset = StoredSetting.update_changeset(context.record, attrs)
      assert changeset.valid?
    end

    test "returns an invalid changeset if both `data` and `encrypted_data` are given", context do
      # `data` should already be in `context.record`
      assert Map.has_key?(context.record, :data)

      attrs = %{
        "encrypted_data" => %{value: "some_encrypted_value"},
        "originator" => %System{}
      }

      changeset = StoredSetting.update_changeset(context.record, attrs)

      refute changeset.valid?

      assert changeset.errors == [
               {[:data, :encrypted_data],
                {"only one must be present", [validation: :only_one_required]}}
             ]
    end

    test "returns an invalid changeset if the `value` is not in the `options`", context do
      attrs = %{
        # options: %{
        #   array: ["some_data_value", "another_allowed_value"]
        # },
        "data" => %{value: "not_allowed"},
        "originator" => %System{}
      }

      changeset = StoredSetting.update_changeset(context.record, attrs)

      refute changeset.valid?

      assert changeset.errors == [
               value: {"must be one of 'one', 'two', 'three'", [validation: :value_not_allowed]}
             ]
    end
  end
end
