defmodule EWalletAPI.ConfigTest do
  # `async: false` because `Application.put_env/3` have side effects
  use EWalletAPI.ConnCase, async: false
  alias EWalletDB.Setting

  describe "ewallet_api.enable_standalone" do
    test "allows /user.signup when configured to true" do
      {:ok, _} = Setting.update("enable_standalone", %{value: true})

      response = client_request("/user.signup")

      # Asserting `user:invalid_email` is good enough to verify
      # that the endpoint is accessible and being processed.
      assert response["data"]["code"] == "user:invalid_email"
    end

    test "prohibits /user.signup when configured to false" do
      {:ok, _} = Setting.update("enable_standalone", %{value: false})

      response = client_request("/user.signup")

      assert response["data"]["code"] == "client:endpoint_not_found"
    end
  end
end
