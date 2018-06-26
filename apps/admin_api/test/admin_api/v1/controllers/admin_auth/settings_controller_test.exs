defmodule AdminAPI.V1.AdminAuth.SettingsControllerTest do
  use AdminAPI.ConnCase, async: true

  describe "/get_settings" do
    test "responds with a list of tokens" do
      response = admin_user_request("/settings.all")

      assert response["success"]
      assert Map.has_key?(response["data"], "tokens")
      assert is_list(response["data"]["tokens"])
    end
  end
end
