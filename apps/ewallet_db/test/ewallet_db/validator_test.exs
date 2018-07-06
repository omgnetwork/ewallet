defmodule EWalletDB.ValidatorTest do
  use ExUnit.Case
  import Ecto.Changeset
  import EWalletDB.Validator

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

  describe "validate_password/1" do
    test "returns {:ok, password} if the password meets requirements" do
      assert validate_password("valid_password") == {:ok, "valid_password"}
    end

    test "returns {:error, :too_short, data} if the password is nil" do
      assert validate_password(nil) == {:error, :too_short, [min_length: 8]}
    end

    test "returns {:error, :too_short, data} if the password is empty" do
      assert validate_password("") == {:error, :too_short, [min_length: 8]}
    end

    test "returns {:error, :too_short, data} if the password is shorter than 8 chars" do
      assert validate_password("short") == {:error, :too_short, [min_length: 8]}
    end
  end

  describe "validate_password/2" do
    test "returns valid if the password meets the requirements" do
      struct = %SampleStruct{
        attr1: "valid_password"
      }

      changeset =
        struct
        |> cast(%{attr1: "valid_password"}, [:attr1])
        |> validate_password(:attr1)

      assert changeset.valid?
    end

    test "returns invalid if the password is empty" do
      changeset =
        %SampleStruct{}
        |> cast(%{attr1: ""}, [:attr1])
        |> validate_password(:attr1)

      refute changeset.valid?
      assert changeset.errors == [{:attr1, {"must be 8 characters or more", []}}]
    end

    test "returns invalid if the password is shorter than 8 chars" do
      changeset =
        %SampleStruct{}
        |> cast(%{attr1: "short"}, [:attr1])
        |> validate_password(:attr1)

      refute changeset.valid?
      assert changeset.errors == [{:attr1, {"must be 8 characters or more", []}}]
    end
  end

  describe "validate_different_values/3" do
    test "valid if values are different" do
      attrs = %{
        attr1: "value",
        attr2: "different_value"
      }

      changeset =
        %SampleStruct{}
        |> cast(attrs, [:attr1, :attr2])
        |> validate_different_values(:attr1, :attr2)

      assert changeset.valid?
    end

    test "returns invalid if values are the same" do
      attrs = %{
        attr1: "same_value",
        attr2: "same_value"
      }

      changeset =
        %SampleStruct{}
        |> cast(attrs, [:attr1, :attr2])
        |> validate_different_values(:attr1, :attr2)

      refute changeset.valid?

      assert changeset.errors == [
               {:attr2, {"can't have the same value as `attr1`", [validation: :different_values]}}
             ]
    end
  end
end
