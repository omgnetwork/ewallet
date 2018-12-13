defmodule AdminAPI.V1.AdminAuth.StatusControllerTest do
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
    test "returns correct error response format and error description" do
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
          admin_user_request("/status.server_error")
        end)

      assert status == 500
      assert Parser.parse!(response) == expected
    end

    test "sends a report to sentry" do
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
        admin_user_request("/status.server_error")
      rescue
        e ->
          Sentry.capture_exception(e, result: :sync)
      end

      Application.put_env(:sentry, :dsn, original_dsn)
      Application.put_env(:sentry, :included_environments, original_included_envs)
    end
  end
end
