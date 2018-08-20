defmodule EWalletAPI.V1.StandalonePlugTest do
  # not async because we're using `Application.put_env/3`
  use EWalletAPI.ConnCase, async: false
  alias EWalletAPI.V1.StandalonePlug

  describe "call/2" do
    test "does not halt if ewallet_api.enable_standalone is true" do
      conn =
        run_with(:enable_standalone, true, fn ->
          StandalonePlug.call(build_conn(), [])
        end)

      refute conn.halted
    end

    test "halts if ewallet_api.enable_standalone is false" do
      conn =
        run_with(:enable_standalone, false, fn ->
          StandalonePlug.call(build_conn(), [])
        end)

      assert conn.halted
    end
  end
end
