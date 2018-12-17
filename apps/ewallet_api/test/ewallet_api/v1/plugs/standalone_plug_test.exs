defmodule EWalletAPI.V1.StandalonePlugTest do
  use EWalletAPI.ConnCase, async: true
  alias EWalletAPI.V1.StandalonePlug
  alias EWalletConfig.Config
  alias ActivityLogger.System

  describe "call/2" do
    test "does not halt if ewallet_api.enable_standalone is true", meta do
      {:ok, [enable_standalone: {:ok, _}]} =
        Config.update(
          %{
            enable_standalone: true,
            originator: %System{}
          },
          meta[:config_pid]
        )

      conn = StandalonePlug.call(build_conn(), [])
      refute conn.halted
    end

    test "halts if ewallet_api.enable_standalone is false", meta do
      {:ok, [enable_standalone: {:ok, _}]} =
        Config.update(
          %{
            enable_standalone: false,
            originator: %System{}
          },
          meta[:config_pid]
        )

      conn = StandalonePlug.call(build_conn(), [])
      assert conn.halted
    end
  end
end
