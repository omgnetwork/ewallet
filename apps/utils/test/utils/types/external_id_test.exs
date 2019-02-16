# Copyright 2019 OmiseGO Pte Ltd
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

defmodule Utils.Types.ExternalIDTest do
  use ExUnit.Case, async: true
  alias Utils.Types.ExternalID

  describe "cast/1" do
    test "casts input to lower case" do
      assert ExternalID.cast("ACC_01CA56X1ZTJD9DZ7H10BZ6VMZX") ==
               {:ok, "acc_01ca56x1ztjd9dz7h10bz6vmzx"}
    end

    test "returns error if the input does not have prefix" do
      assert ExternalID.cast("01ca56x1ztjd9dz7h10bz6vmzx") == :error
    end

    test "returns error if the input has invalid length" do
      assert ExternalID.cast("acc_01ca56x1ztj") == :error
    end
  end

  describe "load/1" do
    # The external ID is stored as string in the database.
    ## So no transformation needed.
    test "returns the same string" do
      assert ExternalID.load("acc_01ca56x1ztjd9dz7h10bz6vmzx") ==
               {:ok, "acc_01ca56x1ztjd9dz7h10bz6vmzx"}
    end
  end

  describe "dump/1" do
    # The external ID should've already been casted via `cast/1` to a uniformed format.
    # So no transformation needed.
    test "returns the same string" do
      assert ExternalID.dump("acc_01ca56x1ztjd9dz7h10bz6vmzx") ==
               {:ok, "acc_01ca56x1ztjd9dz7h10bz6vmzx"}
    end
  end

  describe "generate/1" do
    test "returns an external ID" do
      generated = ExternalID.generate("abc_")
      assert String.match?(generated, ~r/^abc_[0-9a-z]{26}$/)
    end

    test "returns an external ID where the prefix contains numbers" do
      generated = ExternalID.generate("ab0_")
      assert String.match?(generated, ~r/^ab0_[0-9a-z]{26}$/)
    end

    test "returns :error if prefix is not provided" do
      assert ExternalID.generate("") == :error
    end

    test "returns :error if prefix is not 3 characters + an underscore" do
      assert ExternalID.generate("abc") == :error
      assert ExternalID.generate("ab_") == :error
      assert ExternalID.generate("ab__") == :error
    end
  end

  describe "autogenerate/1" do
    test "returns an external ID" do
      generated = ExternalID.autogenerate("sym_")
      assert String.match?(generated, ~r/^sym_[0-9a-z]{26}$/)
    end
  end
end
