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

defmodule EWallet.HelperTest do
  use ExUnit.Case, async: true
  alias EWallet.Helper

  describe "to_existing_atoms/1" do
    test "converts strings to atoms" do
      # Atoms exist since compile, so by the time we invoke the asserted atoms would already exist.
      assert Helper.to_existing_atoms(["one", "two"]) == [:one, :two]
    end

    test "skips strings that are not existing atoms" do
      # Atoms exist since compile, so by the time we invoke the asserted atoms would already exist.
      assert Helper.to_existing_atoms(["exists", "doesnt_exist_anywhere_z93Gh4g0f"]) == [:exists]
    end
  end

  describe "members?/2" do
    test "returns true if all elements exist in the enumerable" do
      assert Helper.members?([1, 2, 3, 4, 5], [3, 4])
    end

    test "returns false if not all elements exist in the enumerable" do
      refute Helper.members?([3, 4], [1, 2, 3, 4, 5])
    end
  end
end
