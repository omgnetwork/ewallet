defmodule EWallet.Web.V1.ErrorHandlerTest do
  # async: false due to `Application.put_env/3` for sentry reporting
  use ExUnit.Case, async: false
  alias EWallet.Web.V1.ErrorHandler
  alias Plug.Conn

  @errors %{
    error_code_one: %{
      code: "error:code_one",
      description: "This is error code #1."
    },
    internal_server_error: %{
      code: "server:internal_server_error",
      description: "Something went wrong on the server."
    }
  }

  describe "build_error/3" do
    test "sends a report to sentry when the given error code could not be found" do
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

      ErrorHandler.build_error(:unknown_code, @errors)

      # Because Bypass takes some time to serve the endpoint and Sentry uses
      # `Task.Supervisor.async_nolink/3` deep inside its code, the only way
      # to wait for the reporting to complete is to sleep...
      :timer.sleep(1000)

      Application.put_env(:sentry, :dsn, original_dsn)
      Application.put_env(:sentry, :included_environments, original_included_envs)
    end
  end
end
