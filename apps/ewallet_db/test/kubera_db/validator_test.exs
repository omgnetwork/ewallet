defmodule EWalletDB.ValidatorTest do
  use ExUnit.Case
  import Ecto.Changeset
  import EWalletDB.Validator

  defmodule SampleStruct do
    use Ecto.Schema

    schema "sample_structs" do
      field :attr1, :string
      field :attr2, :string
      field :attr3, :string
    end
  end

  describe "validate_required_exclusive/2" do
    test "valid if only one field is present" do
      attrs = %{
        attr1: "value",
        attr2: nil,
        attr3: nil
      }

      changeset = %SampleStruct{}
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

      changeset = %SampleStruct{}
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

      changeset = %SampleStruct{}
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

      changeset = %SampleStruct{}
        |> cast(attrs, [:attr1, :attr2, :attr3])
        |> validate_required_exclusive(%{attr1: nil, attr2: nil, attr3: nil})

      refute changeset.valid?
      assert changeset.errors ==
        [{%{attr1: nil, attr2: nil, attr3: nil}, {"can't all be blank", []}}]
    end

    test "invalid if more than one field is present" do
      attrs = %{
        attr1: "value",
        attr2: "extra_value",
        attr3: "another_extra_value",
      }

      changeset = %SampleStruct{}
        |> cast(attrs, [:attr1, :attr2, :attr3])
        |> validate_required_exclusive(%{attr1: nil, attr2: nil, attr3: nil})

      refute changeset.valid?
      assert changeset.errors ==
        [{%{attr1: nil, attr2: nil, attr3: nil}, {"only one must be present", []}}]
    end

    test "invalid if more than one field is present with an attribute value given" do
      attrs = %{
        attr1: "value",
        attr2: "test",
        attr3: nil
      }

      changeset = %SampleStruct{}
        |> cast(attrs, [:attr1, :attr2, :attr3])
        |> validate_required_exclusive(%{attr1: "value", attr2: nil, attr3: nil})

      refute changeset.valid?
      assert changeset.errors ==
        [{%{attr1: "value", attr2: nil, attr3: nil}, {"only one must be present", []}}]
    end
  end

  describe "validate_required_all_or_none/2" do
    test "returns valid if all attributes are present" do
      attrs = %{
        attr1: "value1",
        attr2: "value2",
        attr3: "value3"
      }

      changeset = %SampleStruct{}
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

      changeset = %SampleStruct{}
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

      changeset = %SampleStruct{}
        |> cast(attrs, [:attr1, :attr2, :attr3])
        |> validate_required_all_or_none(%{attr1: nil, attr2: nil, attr3: nil})

      refute changeset.valid?
      assert changeset.errors ==
        [{%{attr1: nil, attr2: nil, attr3: nil}, {"either all or none of them must be present", [validation: "all_or_none"]}}]
    end

    test "returns invalid if only some of the attributes are present" do
      attrs = %{
        attr1: "value1",
        attr2: "",
        attr3: "value3"
      }

      changeset = %SampleStruct{}
        |> cast(attrs, [:attr1, :attr2, :attr3])
        |> validate_required_all_or_none(%{attr1: nil, attr2: nil, attr3: nil})

      refute changeset.valid?
      assert changeset.errors ==
        [{%{attr1: nil, attr2: nil, attr3: nil}, {"either all or none of them must be present", [validation: "all_or_none"]}}]
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
