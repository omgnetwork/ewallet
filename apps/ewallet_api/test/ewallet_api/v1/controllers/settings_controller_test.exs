defmodule EWalletAPI.V1.SettingsControllerTest do
  use EWalletAPI.ConnCase, async: true

  describe "/get_settings" do
    test "responds with a list of tokens" do
      response = provider_request("/get_settings")

      assert response["success"]
      assert Map.has_key?(response["data"], "tokens")
      assert is_list(response["data"]["tokens"])
    end
  end
end
