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

defmodule Utils.Helpers.NormalizeTest do
  use ExUnit.Case, async: true
  alias Utils.Helpers.Normalize

  describe "string_to_boolean/1" do
    test "converts strings to boolean" do
      assert Normalize.string_to_boolean("yes")
      assert Normalize.string_to_boolean("Yes")
      assert Normalize.string_to_boolean("true")
      assert Normalize.string_to_boolean("True")
      assert Normalize.string_to_boolean("yup")
      assert Normalize.string_to_boolean("yo")
      assert Normalize.string_to_boolean("yawn")
      assert Normalize.string_to_boolean("1")
      refute Normalize.string_to_boolean("nope")
      refute Normalize.string_to_boolean("no")
      refute Normalize.string_to_boolean("false")
      refute Normalize.string_to_boolean("0")
      refute Normalize.string_to_boolean(1)
      refute Normalize.string_to_boolean(true)
      refute Normalize.string_to_boolean(false)
    end
  end

  describe "to_boolean/1" do
    test "converts strings to boolean" do
      assert Normalize.to_boolean("yes")
      assert Normalize.to_boolean("Yes")
      assert Normalize.to_boolean("true")
      assert Normalize.to_boolean("True")
      assert Normalize.to_boolean("yup")
      assert Normalize.to_boolean("yo")
      assert Normalize.to_boolean("yawn")
      assert Normalize.to_boolean("1")
      refute Normalize.to_boolean("nope")
      refute Normalize.to_boolean("no")
      refute Normalize.to_boolean("false")
      refute Normalize.to_boolean("0")
    end

    test "converts boolean to boolean" do
      assert Normalize.to_boolean(true)
      refute Normalize.to_boolean(false)
    end

    test "converts integer to boolean" do
      assert Normalize.to_boolean(1)
      assert Normalize.to_boolean(2)
      assert Normalize.to_boolean(65_535)
      assert Normalize.to_boolean(99_999)
      refute Normalize.to_boolean(0)
      refute Normalize.to_boolean(-1)
    end
  end
end
