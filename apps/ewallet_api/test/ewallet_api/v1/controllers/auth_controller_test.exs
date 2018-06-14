defmodule EWalletAPI.V1.AuthControllerTest do
  use EWalletAPI.ConnCase, async: true

  describe "/me.logout" do
    test "responds success with empty response if logout successfully" do
      response = client_request("/me.logout")

      assert response["version"] == @expected_version
      assert response["success"] == true
      assert response["data"] == %{}
    end
  end
end
