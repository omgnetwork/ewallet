defmodule KuberaAdmin.V1.SelfControllerTest do
  use KuberaAdmin.ConnCase, async: true

  describe "/me.get" do
    test "responds with user data" do
      response = user_request("/me.get")

      assert response["success"]
      assert response["data"]["username"] == @username
    end
  end
end
