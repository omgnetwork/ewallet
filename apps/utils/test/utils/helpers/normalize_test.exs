# Copyright 2018-2019 OmiseGO Pte Ltd
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
  alias Utils.Helpers.Normalize.ToBooleanError

  describe "string_to_boolean/1" do
    test "converts strings to boolean" do
      assert Normalize.string_to_boolean("yes")
      assert Normalize.string_to_boolean("Yes")
      assert Normalize.string_to_boolean("true")
      assert Normalize.string_to_boolean("True")
      assert Normalize.string_to_boolean("1")
      refute Normalize.string_to_boolean("false")
      refute Normalize.string_to_boolean("0")
      refute Normalize.string_to_boolean("no")
      assert_raise(ToBooleanError, fn -> Normalize.string_to_boolean("nope") end)

      assert_raise(ToBooleanError, fn -> Normalize.string_to_boolean("yup") end)
      assert_raise(ToBooleanError, fn -> Normalize.string_to_boolean("yo") end)
      assert_raise(ToBooleanError, fn -> Normalize.string_to_boolean("yawn") end)
      assert_raise(ToBooleanError, fn -> Normalize.string_to_boolean(1) end)
      assert_raise(ToBooleanError, fn -> Normalize.string_to_boolean(true) end)
      assert_raise(ToBooleanError, fn -> Normalize.string_to_boolean(false) end)
    end
  end

  describe "to_boolean/1" do
    test "converts strings to boolean" do
      assert Normalize.to_boolean("yes")
      assert Normalize.to_boolean("Yes")
      assert Normalize.to_boolean("true")
      assert Normalize.to_boolean("True")
      assert Normalize.to_boolean("1")
      refute Normalize.to_boolean("false")
      refute Normalize.to_boolean("0")
      refute Normalize.to_boolean("no")
      assert_raise(ToBooleanError, fn -> Normalize.to_boolean("nope") end)
      assert_raise(ToBooleanError, fn -> assert Normalize.to_boolean("yup") end)
      assert_raise(ToBooleanError, fn -> Normalize.to_boolean("yo") end)
      assert_raise(ToBooleanError, fn -> Normalize.to_boolean("yawn") end)
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
      assert_raise(ToBooleanError, fn -> Normalize.to_boolean(0) end)
      assert_raise(ToBooleanError, fn -> Normalize.to_boolean(-1) end)
    end
  end

  describe "to_integer/1" do
    test "keeps integers as integers" do
      assert 1 == Normalize.to_integer(1)
      assert 2 == Normalize.to_integer(2)
      assert 65_535 == Normalize.to_integer(65_535)
      assert 99_999 == Normalize.to_integer(99_999)
      assert 0 == Normalize.to_integer(0)
      assert -1 == Normalize.to_integer(-1)
    end

    test "converts binaries to integer" do
      assert 1 == Normalize.to_integer(<<"1">>)
      assert 2 == Normalize.to_integer(<<"2">>)
      assert 65_535 == Normalize.to_integer(<<"65535">>)
      assert 99_999 == Normalize.to_integer(<<"99999">>)
      assert 999_991 == Normalize.to_integer(<<"99999", "1">>)
      assert 0 == Normalize.to_integer(<<"0">>)
      assert -1 == Normalize.to_integer(<<"-1">>)
    end

    test "converts lists to integer" do
      assert 1 == Normalize.to_integer('1')
      assert 2 == Normalize.to_integer('2')
      assert 65_535 == Normalize.to_integer('65535')
      assert 99_999 == Normalize.to_integer('99999')
      assert 999_991 == Normalize.to_integer('999991')
      assert 0 == Normalize.to_integer('0')
      assert -1 == Normalize.to_integer('-1')
    end

    test "converts floats to integer" do
      assert 1 == Normalize.to_integer(1.0)
      assert 2 == Normalize.to_integer(2.0)
      assert 65_535 == Normalize.to_integer(65_535.0)
      assert 99_999 == Normalize.to_integer(99_999.0)
      assert 999_991 == Normalize.to_integer(999_991.0)
      assert 0 == Normalize.to_integer(0.0)
      assert -1 == Normalize.to_integer(-1.0)

      assert 1 == Normalize.to_integer(1.1)
      assert 2 == Normalize.to_integer(2.2)
      assert 65_535 == Normalize.to_integer(65_535.3)
      assert 99_999 == Normalize.to_integer(99_999.4)
      assert 999_992 == Normalize.to_integer(999_991.5)
      assert 0 == Normalize.to_integer(0.0)
      assert -1 == Normalize.to_integer(-1.0)
      assert -1 == Normalize.to_integer(-1.4)
      assert -2 == Normalize.to_integer(-1.5)
    end
  end
end
