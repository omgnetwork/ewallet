defmodule EWalletAPI.V1.StandalonePlugTest do
  # not async because we're using `Application.put_env/3`
  use EWalletAPI.ConnCase, async: true
  alias EWalletAPI.V1.StandalonePlug
  alias EWalletConfig.Config

  describe "call/2" do
    test "does not halt if ewallet_api.enable_standalone is true", meta do
      {:ok, _} = Config.update("enable_standalone", %{value: true}, meta[:config_pid])

      conn = StandalonePlug.call(build_conn(), [])
      refute conn.halted
    end

    test "halts if ewallet_api.enable_standalone is false", meta do
      {:ok, _} = Config.update("enable_standalone", %{value: false}, meta[:config_pid])

      conn = StandalonePlug.call(build_conn(), [])
      assert conn.halted
    end
  end
end
