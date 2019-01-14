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

defmodule EWalletDB.ValidatorTest do
  use EWalletDB.SchemaCase, async: true
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

  describe "validate_password/1" do
    test "returns {:ok, password} if the password meets requirements" do
      assert validate_password("valid_password") == {:ok, "valid_password"}
    end

    test "returns {:error, :password_too_short, data} if the password is nil" do
      assert validate_password(nil) == {:error, :password_too_short, [min_length: 8]}
    end

    test "returns {:error, :password_too_short, data} if the password is empty" do
      assert validate_password("") == {:error, :password_too_short, [min_length: 8]}
    end

    test "returns {:error, :password_too_short, data} if the password is shorter than 8 chars" do
      assert validate_password("short") == {:error, :password_too_short, [min_length: 8]}
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

  describe "validate_email/2" do
    test "returns a valid changeset if the attribute meets the requirements" do
      changeset =
        %SampleStruct{}
        |> cast(%{attr1: "valid.email@example.com"}, [:attr1])
        |> validate_email(:attr1)

      assert changeset.valid?
    end

    test "returns an invalid changeset if the attribute does not have '@' sign" do
      changeset =
        %SampleStruct{}
        |> cast(%{attr1: "not.an.email"}, [:attr1])
        |> validate_email(:attr1)

      refute changeset.valid?
    end

    test "returns an invalid changeset if the attribute is an empty string" do
      changeset =
        %SampleStruct{}
        |> cast(%{attr1: ""}, [:attr1])
        |> validate_email(:attr1)

      refute changeset.valid?
    end

    test "returns an invalid changeset if the attribute is nil" do
      changeset =
        %SampleStruct{}
        |> cast(%{attr1: nil}, [:attr1])
        |> validate_email(:attr1)

      refute changeset.valid?
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
