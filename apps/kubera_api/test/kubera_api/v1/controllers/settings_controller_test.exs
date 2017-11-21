defmodule KuberaAPI.V1.SettingsControllerTest do
  use KuberaAPI.ConnCase, async: true

  describe "/get_settings" do
    test "responds with a list of minted_tokens" do
      response = provider_request("/get_settings")

      assert response["success"]
      assert Map.has_key?(response["data"], "minted_tokens")
      assert is_list(response["data"]["minted_tokens"])
    end
  end
end
