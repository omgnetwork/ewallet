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

defmodule AdminAPI.V1.StatusControllerTest do
  # async: false due to `Application.put_env/3` for sentry reporting
  use AdminAPI.ConnCase, async: false
  alias Plug.Conn
  alias Poison.Parser

  describe "/status" do
    test "returns success" do
      assert unauthenticated_request("/status") == %{"success" => true}
    end
  end

  describe "/status.server_error" do
    test_with_auths "returns correct error response format and error description" do
      expected = %{
        "version" => "1",
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "server:internal_server_error",
          "description" => "Mock server error",
          "messages" => nil
        }
      }

      # Note this test use a different approach to calling and asserting.
      # This is because a raised error get sent all the way up to the test
      # instead of being handled by Phoenix and return a response.
      #
      # See example: /phoenix/test/phoenix/endpoint/render_errors_test.exs
      {status, _headers, response} =
        assert_error_sent(500, fn ->
          request("/status.server_error")
        end)

      assert status == 500
      assert Parser.parse!(response) == expected
    end

    test_with_auths "sends a report to sentry" do
      bypass = Bypass.open()

      Bypass.expect(bypass, fn conn ->
        assert conn.halted == false
        assert conn.method == "POST"
        assert conn.request_path == "/api/1/store/"

        Conn.resp(conn, 200, ~s'{"id": "1234"}')
      end)

      original_dsn = Application.get_env(:sentry, :dsn)
      original_included_envs = Application.get_env(:sentry, :included_environments)

      Application.put_env(:sentry, :dsn, "http://public@localhost:#{bypass.port}/1")
      Application.put_env(:sentry, :included_environments, [:test | original_included_envs])

      try do
        request("/status.server_error")
      rescue
        # Ignores the re-raised error
        _ ->
          :noop
      end

      # Because Bypass takes some time to serve the endpoint and Sentry uses
      # `Task.Supervisor.async_nolink/3` deep inside its code, the only way
      # to wait for the reporting to complete is to sleep...
      :timer.sleep(1000)

      Application.put_env(:sentry, :dsn, original_dsn)
      Application.put_env(:sentry, :included_environments, original_included_envs)
    end
  end
end
