defmodule EWalletAPI.V1.StandalonePlugTest do
  # not async because we're using `Application.put_env/3`
  use EWalletAPI.ConnCase, async: false
  alias EWalletAPI.V1.StandalonePlug
  alias EWalletDB.Setting

  describe "call/2" do
    test "does not halt if ewallet_api.enable_standalone is true" do
      {:ok, _} = Setting.update("enable_standalone", %{value: true})

      conn = StandalonePlug.call(build_conn(), [])
      refute conn.halted
    end

    test "halts if ewallet_api.enable_standalone is false" do
      {:ok, _} = Setting.update("enable_standalone", %{value: false})

      conn = StandalonePlug.call(build_conn(), [])
      assert conn.halted
    end
  end
end
