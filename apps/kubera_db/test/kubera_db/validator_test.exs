defmodule KuberaDB.ValidatorTest do
  use ExUnit.Case
  import Ecto.Changeset
  import KuberaDB.Validator

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
        |> validate_required_exclusive([:attr1, :attr2, :attr3])

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
        |> validate_required_exclusive([:attr1, :attr2, :attr3])

      refute changeset.valid?
      assert changeset.errors ==
        [{[:attr1, :attr2, :attr3], {"can't all be blank", []}}]
    end

    test "invalid if more than one field is present" do
      attrs = %{
        attr1: "value",
        attr2: "extra_value",
        attr3: "another_extra_value",
      }

      changeset = %SampleStruct{}
        |> cast(attrs, [:attr1, :attr2, :attr3])
        |> validate_required_exclusive([:attr1, :attr2, :attr3])

      refute changeset.valid?
      assert changeset.errors ==
        [{[:attr1, :attr2, :attr3], {"only one must be present", []}}]
    end
  end
end
