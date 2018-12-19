defmodule EWalletAPI.ConfigTest do
  use EWalletAPI.ConnCase, async: true
  alias EWalletConfig.Config
  alias ActivityLogger.System

  describe "ewallet_api.enable_standalone" do
    test "allows /user.signup when configured to true", meta do
      {:ok, [enable_standalone: {:ok, _}]} =
        Config.update(
          %{
            enable_standalone: true,
            originator: %System{}
          },
          meta[:config_pid]
        )

      response = client_request("/user.signup")

      # Asserting `user:invalid_email` is good enough to verify
      # that the endpoint is accessible and being processed.
      assert response["data"]["code"] == "user:invalid_email"
    end

    test "prohibits /user.signup when configured to false", meta do
      {:ok, [enable_standalone: {:ok, _}]} =
        Config.update(
          %{
            enable_standalone: false,
            originator: %System{}
          },
          meta[:config_pid]
        )

      response = client_request("/user.signup")

      assert response["data"]["code"] == "client:endpoint_not_found"
    end
  end
end
