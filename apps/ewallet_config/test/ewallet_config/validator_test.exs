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

defmodule EWalletConfig.ValidatorTest do
  use EWalletConfig.SchemaCase, async: true
  import Ecto.Changeset
  import EWalletConfig.Validator

  defmodule SampleStruct do
    use Ecto.Schema

    schema "sample_structs" do
      field(:attr1, :string)
      field(:attr2, :string)
      field(:attr3, :string)
    end
  end

  describe "validate_required_exclusive/2" do
    test "valid if only one field is present" do
      attrs = %{
        attr1: "value",
        attr2: nil,
        attr3: nil
      }

      changeset =
        %SampleStruct{}
        |> cast(attrs, [:attr1, :attr2, :attr3])
        |> validate_required_exclusive(%{attr1: nil, attr2: nil, attr3: nil})

      assert changeset.valid?
    end

    test "valid if the attribute value matches the given value" do
      attrs = %{
        attr1: "value",
        attr2: nil,
        attr3: nil
      }

      changeset =
        %SampleStruct{}
        |> cast(attrs, [:attr1, :attr2, :attr3])
        |> validate_required_exclusive(%{attr1: "value", attr2: nil, attr3: nil})

      assert changeset.valid?
    end

    test "valid if the attr value does not match the given value and another field is present" do
      attrs = %{
        attr1: "value",
        attr2: "test",
        attr3: nil
      }

      changeset =
        %SampleStruct{}
        |> cast(attrs, [:attr1, :attr2, :attr3])
        |> validate_required_exclusive(%{attr1: "something", attr2: nil, attr3: nil})

      assert changeset.valid?
    end

    test "invalid if no field is present" do
      attrs = %{
        attr1: nil,
        attr2: nil,
        attr3: nil
      }

      changeset =
        %SampleStruct{}
        |> cast(attrs, [:attr1, :attr2, :attr3])
        |> validate_required_exclusive(%{attr1: nil, attr2: nil, attr3: nil})

      refute changeset.valid?

      assert changeset.errors ==
               [
                 {%{attr1: nil, attr2: nil, attr3: nil},
                  {"can't all be blank", [validation: :required_exclusive]}}
               ]
    end

    test "invalid if more than one field is present" do
      attrs = %{
        attr1: "value",
        attr2: "extra_value",
        attr3: "another_extra_value"
      }

      changeset =
        %SampleStruct{}
        |> cast(attrs, [:attr1, :attr2, :attr3])
        |> validate_required_exclusive(%{attr1: nil, attr2: nil, attr3: nil})

      refute changeset.valid?

      assert changeset.errors ==
               [
                 {%{attr1: nil, attr2: nil, attr3: nil},
                  {"only one must be present", [validation: :only_one_required]}}
               ]
    end

    test "invalid if more than one field is present with an attribute value given" do
      attrs = %{
        attr1: "value",
        attr2: "test",
        attr3: nil
      }

      changeset =
        %SampleStruct{}
        |> cast(attrs, [:attr1, :attr2, :attr3])
        |> validate_required_exclusive(%{attr1: "value", attr2: nil, attr3: nil})

      refute changeset.valid?

      assert changeset.errors ==
               [
                 {%{attr1: "value", attr2: nil, attr3: nil},
                  {"only one must be present", [validation: :only_one_required]}}
               ]
    end
  end

  describe "validate_required_all_or_none/2" do
    test "returns valid if all attributes are present" do
      attrs = %{
        attr1: "value1",
        attr2: "value2",
        attr3: "value3"
      }

      changeset =
        %SampleStruct{}
        |> cast(attrs, [:attr1, :attr2, :attr3])
        |> validate_required_all_or_none(%{attr1: nil, attr2: nil, attr3: nil})

      assert changeset.valid?
    end

    test "returns valid if none of the attributes is present" do
      attrs = %{
        attr1: "",
        attr2: "",
        attr3: ""
      }

      changeset =
        %SampleStruct{}
        |> cast(attrs, [:attr1, :attr2, :attr3])
        |> validate_required_all_or_none(%{attr1: nil, attr2: nil, attr3: nil})

      assert changeset.valid?
    end

    test "returns invalid if only one attribute is present" do
      attrs = %{
        attr1: "",
        attr2: "value2",
        attr3: ""
      }

      changeset =
        %SampleStruct{}
        |> cast(attrs, [:attr1, :attr2, :attr3])
        |> validate_required_all_or_none(%{attr1: nil, attr2: nil, attr3: nil})

      refute changeset.valid?

      assert changeset.errors ==
               [
                 {%{attr1: nil, attr2: nil, attr3: nil},
                  {"either all or none of them must be present", [validation: "all_or_none"]}}
               ]
    end

    test "returns invalid if only some of the attributes are present" do
      attrs = %{
        attr1: "value1",
        attr2: "",
        attr3: "value3"
      }

      changeset =
        %SampleStruct{}
        |> cast(attrs, [:attr1, :attr2, :attr3])
        |> validate_required_all_or_none(%{attr1: nil, attr2: nil, attr3: nil})

      refute changeset.valid?

      assert changeset.errors ==
               [
                 {%{attr1: nil, attr2: nil, attr3: nil},
                  {"either all or none of them must be present", [validation: "all_or_none"]}}
               ]
    end
  end

  describe "validate_immutable/2" do
    test "returns valid if provider_user_id has not been set before" do
      struct =
        %SampleStruct{}
        |> cast(%{attr1: nil}, [:attr1])
        |> apply_changes()

      changeset =
        struct
        |> cast(%{attr1: "new_value"}, [:attr1])
        |> validate_immutable(:attr1)

      assert changeset.valid?
    end

    test "returns valid if provider_user_id is unchanged" do
      struct =
        %SampleStruct{}
        |> cast(%{attr1: "old_value"}, [:attr1])
        |> apply_changes()

      changeset =
        struct
        |> cast(%{attr1: "old_value"}, [:attr1])
        |> validate_immutable(:attr1)

      assert changeset.valid?
    end

    test "returns invalid if provider_user_id changed" do
      struct =
        %SampleStruct{}
        |> cast(%{attr1: "old_value"}, [:attr1])
        |> apply_changes()

      changeset =
        struct
        |> cast(%{attr1: "new_value"}, [:attr1])
        |> validate_immutable(:attr1)

      refute changeset.valid?
      assert changeset.errors == [{:attr1, {"can't be changed", []}}]
    end
  end
end
