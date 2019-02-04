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

defmodule Utils.Helpers.PathResolverTest do
  use ExUnit.Case, async: true
  alias Utils.Helpers.PathResolver

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

      assert PathResolver.static_dir(:url_dispatcher) ==
               Path.expand("../../../../url_dispatcher/priv/static", __DIR__)

      assert PathResolver.static_dir(:admin_panel) ==
               Path.expand("../../../../admin_panel/priv/static", __DIR__)
    end

    test "returns path to app dir with serve local static" do
      System.put_env("SERVE_LOCAL_STATIC", "no")

      assert PathResolver.static_dir(:url_dispatcher) ==
               Application.app_dir(:url_dispatcher, "priv/static")

      assert PathResolver.static_dir(:admin_panel) ==
               Application.app_dir(:admin_panel, "priv/static")
    end
  end
end
