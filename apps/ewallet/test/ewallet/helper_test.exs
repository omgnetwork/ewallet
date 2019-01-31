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

  describe "to_boolean/1" do
    test "converts strings to boolean" do
      assert Helper.to_boolean("yes")
      assert Helper.to_boolean("Yes")
      assert Helper.to_boolean("true")
      assert Helper.to_boolean("True")
      assert Helper.to_boolean("yup")
      assert Helper.to_boolean("yo")
      assert Helper.to_boolean("yawn")
      assert Helper.to_boolean("1")
      refute Helper.to_boolean("nope")
      refute Helper.to_boolean("no")
      refute Helper.to_boolean("false")
      refute Helper.to_boolean("0")
    end

    test "converts boolean to boolean" do
      assert Helper.to_boolean(true)
      refute Helper.to_boolean(false)
    end

    test "converts integer to boolean" do
      assert Helper.to_boolean(1)
      assert Helper.to_boolean(2)
      assert Helper.to_boolean(65_535)
      assert Helper.to_boolean(99_999)
      refute Helper.to_boolean(0)
      refute Helper.to_boolean(-1)
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

  describe "string_to_boolean/1" do
    test "converts strings to boolean" do
      assert Helper.string_to_boolean("yes")
      assert Helper.string_to_boolean("Yes")
      assert Helper.string_to_boolean("true")
      assert Helper.string_to_boolean("True")
      assert Helper.string_to_boolean("yup")
      assert Helper.string_to_boolean("yo")
      assert Helper.string_to_boolean("yawn")
      assert Helper.string_to_boolean("1")
      refute Helper.string_to_boolean("nope")
      refute Helper.string_to_boolean("no")
      refute Helper.string_to_boolean("false")
      refute Helper.string_to_boolean("0")
      refute Helper.string_to_boolean(1)
      refute Helper.string_to_boolean(true)
      refute Helper.string_to_boolean(false)
    end
  end

  describe "static_dir/1" do
    setup do
      orig = System.get_env("SERVE_LOCAL_STATIC")

      on_exit(fn ->
        case orig do
          n when is_binary(n) ->
            System.put_env("SERVE_LOCAL_STATIC", n)

          nil ->
            System.delete_env("SERVE_LOCAL_STATIC")
        end
      end)

      %{orig: orig}
    end

    test "returns path to app dir without serve local static" do
      System.put_env("SERVE_LOCAL_STATIC", "yes")

      assert Helper.static_dir(:url_dispatcher) ==
               Application.app_dir(:url_dispatcher, "priv/static")

      assert Helper.static_dir(:admin_panel) == Application.app_dir(:admin_panel, "priv/static")
    end

    test "returns path to app dir with serve local static" do
      System.put_env("SERVE_LOCAL_STATIC", "no")

      assert Helper.static_dir(:url_dispatcher) ==
               Path.expand("../../../url_dispatcher/priv/static", __DIR__)

      assert Helper.static_dir(:admin_panel) ==
               Path.expand("../../../admin_panel/priv/static", __DIR__)
    end
  end
end
