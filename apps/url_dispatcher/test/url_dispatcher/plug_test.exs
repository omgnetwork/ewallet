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

defmodule UrlDispatcher.PlugTest do
  use ExUnit.Case, async: true
  use Plug.Test
  alias UrlDispatcher.Plug

  defp request(path) do
    :get
    |> conn(path)
    |> Plug.call([])
  end

  describe "call/2" do
    test "returns success status when requesting /" do
      Application.put_env(:ewallet, :version, "0.9.9")

      conn = request("/")

      refute conn.halted
      assert conn.status == 200

      assert conn.resp_body == ~s({"status":true,"ewallet_version":"0.9.9"})
    end

    test "returns a 200 response when requesting /api" do
      conn = request("/api/client")
      refute conn.halted
      assert conn.status == 200
    end

    test "returns a 200 response when requesting /api/admin" do
      conn = request("/api/admin")
      refute conn.halted
      assert conn.status == 200
    end

    test "returns a 404 response and halts when requesting an unknown endpoint" do
      conn = request("/unknown_endpoint")

      assert conn.halted
      assert conn.status == 404
      assert conn.resp_body == "The url could not be resolved."
    end

    test "returns a 200 response when requesting a file in /public folder" do
      conn = request("/public/uploads/test.txt")

      # Plug.Static returns `%Plug.Conn{halted: true}` on success
      assert conn.halted
      assert conn.status == 200
    end

    test "returns a 404 response and halts when requesting an unknown file /public" do
      conn = request("/unknown_endpoint")

      assert conn.halted
      assert conn.status == 404
      assert conn.resp_body == "The url could not be resolved."
    end

    test "returns a 302 redirect response to /docs/index.html when requesting /docs" do
      conn = request("/docs")

      refute conn.halted
      assert conn.status == 302
      assert conn.resp_body =~ ~s(/docs/index.html)

      assert Enum.any?(conn.resp_headers, fn header ->
               header == {"location", "/docs/index.html"}
             end)
    end
  end
end
