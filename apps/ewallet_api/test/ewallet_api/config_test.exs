defmodule EWalletAPI.ConfigTest do
  # `async: false` because `Application.put_env/3` have side effects
  use EWalletAPI.ConnCase, async: false
  alias EWalletDB.Setting

  describe "ewallet_api.enable_standalone" do
    test "allows /user.signup when configured to true" do
      {:ok, _} = Setting.insert(%{key: "enable_standalone", value: true, type: "boolean"})

      response =
        run_with(:enable_standalone, true, fn ->
          client_request("/user.signup")
        end)

      # Asserting `user:invalid_email` is good enough to verify
      # that the endpoint is accessible and being processed.
      assert response["data"]["code"] == "user:invalid_email"
    end

    test "prohibits /user.signup when configured to false" do
      response =
        run_with(:enable_standalone, false, fn ->
          client_request("/user.signup")
        end)

      assert response["data"]["code"] == "client:endpoint_not_found"
    end
  end
end
