defmodule EWalletConfig.SettingValidatorTest do
  use EWalletConfig.SchemaCase
  import Ecto.Changeset
  import EWalletConfig.SettingValidator
  alias EWalletConfig.StoredSetting

  describe "validate_with_options/1" do
    test "returns a valid changeset for a new StoredSetting" do
      attrs = %{
        data: %{value: "two"},
        options: %{
          array: ["one", "two", "three"]
        }
      }

      changeset =
        %StoredSetting{}
        |> cast(attrs, [:data, :options])
        |> validate_setting_with_options()

      assert changeset.valid?
    end

    test "returns a valid changeset for an existing StoredSetting" do
      setting = %StoredSetting{
        data: %{value: "one"},
        options: %{array: ["one", "two", "three"]}
      }

      attrs = %{data: %{value: "two"}}

      changeset =
        setting
        |> cast(attrs, [:data])
        |> validate_setting_with_options()

      assert changeset.valid?
    end

    test "returns a valid changeset when the options' array is nil" do
      attrs = %{
        data: %{value: "any_value"},
        options: %{
          array: nil
        }
      }

      changeset =
        %StoredSetting{}
        |> cast(attrs, [:data, :options])
        |> validate_setting_with_options()

      assert changeset.valid?
    end

    test "returns a valid changeset when the options did not change" do
      attrs = %{
        key: "new_key",
        data: %{value: "new_value"}
      }

      changeset =
        %StoredSetting{}
        |> cast(attrs, [:key, :data, :options])
        |> validate_setting_with_options()

      assert changeset.valid?
    end

    test "returns an invalid changeset when the value is not in the allowed options" do
      attrs = %{
        data: %{value: "twenty"},
        options: %{
          array: ["one", "two", "three"]
        }
      }

      changeset =
        %StoredSetting{}
        |> cast(attrs, [:data, :options])
        |> validate_setting_with_options()

      refute changeset.valid?

      assert changeset.errors == [
               value: {"must be one of 'one', 'two', 'three'", [validation: :value_not_allowed]}
             ]
    end
  end

  describe "validate_setting_type/1" do
    test "returns a valid changeset for a new StoredSetting" do
      setting = %StoredSetting{}
      attrs = %{type: "string", data: %{value: "new_value"}}

      changeset =
        setting
        |> cast(attrs, [:type, :data])
        |> validate_setting_type()

      assert changeset.valid?
    end

    test "returns a valid changeset for an existing StoredSetting" do
      setting = %StoredSetting{type: "string", data: %{value: "old_value"}}
      attrs = %{data: %{value: "new_value"}}

      changeset =
        setting
        |> cast(attrs, [:type, :data])
        |> validate_setting_with_options()

      assert changeset.valid?
    end

    test "returns a valid changeset when given a nil value" do
      attrs = %{type: "string", data: %{value: nil}}

      changeset =
        %StoredSetting{}
        |> cast(attrs, [:type, :data])
        |> validate_setting_type()

      assert changeset.valid?
    end
  end

  describe "validate_setting_type/1 for type 'string'" do
    test "returns a valid changeset when given a string" do
      attrs = %{type: "string", data: %{value: "string_value"}}

      changeset =
        %StoredSetting{}
        |> cast(attrs, [:type, :data])
        |> validate_setting_type()

      assert changeset.valid?
    end

    test "returns an invalid changeset when given a non-string" do
      attrs = %{type: "string", data: %{value: 1234}}

      changeset =
        %StoredSetting{}
        |> cast(attrs, [:type, :data])
        |> validate_setting_type()

      refute changeset.valid?
    end
  end

  describe "validate_setting_type/1 for type 'integer'" do
    test "returns a valid changeset when given a positive integer value" do
      attrs = %{type: "integer", data: %{value: 1234}}

      changeset =
        %StoredSetting{}
        |> cast(attrs, [:type, :data])
        |> validate_setting_type()

      assert changeset.valid?
    end

    test "returns a valid changeset when given a zero" do
      attrs = %{type: "integer", data: %{value: 0}}

      changeset =
        %StoredSetting{}
        |> cast(attrs, [:type, :data])
        |> validate_setting_type()

      assert changeset.valid?
    end

    test "returns a valid changeset when given a negative integer value" do
      attrs = %{type: "integer", data: %{value: -1234}}

      changeset =
        %StoredSetting{}
        |> cast(attrs, [:type, :data])
        |> validate_setting_type()

      assert changeset.valid?
    end

    test "returns an invalid changeset when given a non-integer" do
      attrs = %{type: "integer", data: %{value: "not_an_integer"}}

      changeset =
        %StoredSetting{}
        |> cast(attrs, [:type, :data])
        |> validate_setting_type()

      refute changeset.valid?
    end
  end

  describe "validate_setting_type/1 for type 'unsigned_integer'" do
    test "returns a valid changeset when given a positive integer value" do
      attrs = %{type: "unsigned_integer", data: %{value: 999}}

      changeset =
        %StoredSetting{}
        |> cast(attrs, [:type, :data])
        |> validate_setting_type()

      assert changeset.valid?
    end

    test "returns a valid changeset when given a zero" do
      attrs = %{type: "unsigned_integer", data: %{value: 0}}

      changeset =
        %StoredSetting{}
        |> cast(attrs, [:type, :data])
        |> validate_setting_type()

      assert changeset.valid?
    end

    test "returns an invalid changeset when given a negative value" do
      attrs = %{type: "unsigned_integer", data: %{value: -1}}

      changeset =
        %StoredSetting{}
        |> cast(attrs, [:type, :data])
        |> validate_setting_type()

      refute changeset.valid?
    end

    test "returns an invalid changeset when given a non-integer" do
      attrs = %{type: "unsigned_integer", data: %{value: "not_an_integer"}}

      changeset =
        %StoredSetting{}
        |> cast(attrs, [:type, :data])
        |> validate_setting_type()

      refute changeset.valid?
    end
  end

  describe "validate_setting_type/1 for type 'map'" do
    test "returns a valid changeset when given a map" do
      attrs = %{type: "map", data: %{value: %{"some_key" => "some_value"}}}

      changeset =
        %StoredSetting{}
        |> cast(attrs, [:type, :data])
        |> validate_setting_type()

      assert changeset.valid?
    end

    test "returns a valid changeset when given a non-map" do
      attrs = %{type: "map", data: %{value: "not_a_map"}}

      changeset =
        %StoredSetting{}
        |> cast(attrs, [:type, :data])
        |> validate_setting_type()

      refute changeset.valid?
    end
  end

  describe "validate_setting_type/1 for type 'array'" do
    test "returns a valid changeset when given an array of strings" do
      attrs = %{type: "array", data: %{value: ["one", "two", "three"]}}

      changeset =
        %StoredSetting{}
        |> cast(attrs, [:type, :data])
        |> validate_setting_type()

      assert changeset.valid?
    end

    test "returns a valid changeset when given an array of integers" do
      attrs = %{type: "array", data: %{value: [1, 2, 3]}}

      changeset =
        %StoredSetting{}
        |> cast(attrs, [:type, :data])
        |> validate_setting_type()

      assert changeset.valid?
    end

    test "returns a valid changeset when given an array of mixed types" do
      attrs = %{type: "array", data: %{value: ["one", 2, "three", false]}}

      changeset =
        %StoredSetting{}
        |> cast(attrs, [:type, :data])
        |> validate_setting_type()

      assert changeset.valid?
    end

    test "returns an invalid changeset when given a non-array" do
      attrs = %{type: "array", data: %{value: "not_an_array"}}

      changeset =
        %StoredSetting{}
        |> cast(attrs, [:type, :data])
        |> validate_setting_type()

      refute changeset.valid?
    end
  end

  describe "validate_setting_type/1 for type 'boolean'" do
    test "returns a valid changeset when given a boolean" do
      attrs = %{type: "boolean", data: %{value: true}}

      changeset =
        %StoredSetting{}
        |> cast(attrs, [:type, :data])
        |> validate_setting_type()

      assert changeset.valid?
    end

    test "returns an invalid changeset when given a non-boolean" do
      attrs = %{type: "boolean", data: %{value: "not_boolean"}}

      changeset =
        %StoredSetting{}
        |> cast(attrs, [:type, :data])
        |> validate_setting_type()

      refute changeset.valid?
    end
  end
end
