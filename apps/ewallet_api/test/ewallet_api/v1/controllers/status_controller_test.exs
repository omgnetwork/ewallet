defmodule EWalletAPI.V1.StatusControllerTest do
  # async: false due to `Application.put_env/3` for sentry reporting
  use EWalletAPI.ConnCase, async: false
  alias Plug.Conn
  alias Poison.Parser

  describe "/status" do
    test "returns success" do
      assert public_request("/status") == %{"success" => true}
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
          client_request("/status.server_error")
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
        client_request("/status.server_error")
      rescue
        # Ignores the re-raised error
        _ -> :noop
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
