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

defmodule EWallet.Web.WebSocketTest do
  use EWallet.DBCase, async: true
  alias EWallet.Web.WebSocket
  alias Plug.Conn

  defmodule MockEndpoint do
  end

  defmodule MockSerializer do
  end

  defmodule MockErrorHandler do
    def handle_error(conn, :invalid_version) do
      Conn.halt(conn)
    end
  end

  describe "default_config/0" do
    test "returns an array of default config" do
      config = WebSocket.default_config()

      assert Keyword.get(config, :timeout) == 60_000
      assert Keyword.get(config, :transport_log) === false
    end
  end

  describe "get_endpoint/4" do
    setup do
      app = :ewallet_test
      accept_header = "some_accept_header"

      :ok =
        Application.put_env(app, :api_versions, %{
          accept_header => %{
            endpoint: MockEndpoint,
            websocket_serializer: MockSerializer
          }
        })

      on_exit(fn ->
        :ok = Application.delete_env(app, :api_versions)
      end)
    end

    test "returns the endpoint and serializer" do
      {res, endpoint, serializer} =
        WebSocket.get_endpoint(
          %Conn{},
          "some_accept_header",
          :ewallet_test,
          &MockErrorHandler.handle_error/2
        )

      assert res == :ok
      assert endpoint == MockEndpoint
      assert serializer == MockSerializer
    end

    test "returns the handled error when the accept header cannot be matched" do
      {res, conn} =
        WebSocket.get_endpoint(
          %Conn{},
          "different_header",
          :ewallet_test,
          &MockErrorHandler.handle_error/2
        )

      assert res == :error
      assert conn.halted
    end
  end

  describe "get_endpoint/3" do
    test "returns the handled error" do
      {res, conn} =
        WebSocket.get_endpoint(%Conn{}, "different_header", &MockErrorHandler.handle_error/2)

      assert res == :error
      assert conn.halted
    end
  end

  describe "update_headers/1" do
    test "returns the params with header keys downcased" do
      conn = %Plug.Conn{params: %{"headers" => %{"Foo" => "bar"}}}
      refute Map.has_key?(conn.params["headers"], "foo")

      params = WebSocket.update_headers(conn)

      assert Map.get(params["headers"], "foo") == "bar"
    end

    test "returns the params with vsn header removed" do
      conn = %Plug.Conn{params: %{"vsn" => "1"}}
      assert Map.has_key?(conn.params, "vsn")

      params = WebSocket.update_headers(conn)

      refute Map.has_key?(params, "vsn")
    end
  end
end
