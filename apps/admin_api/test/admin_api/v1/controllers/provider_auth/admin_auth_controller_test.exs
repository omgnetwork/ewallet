defmodule AdminAPI.V1.ProviderAuth.AdminAuthControllerTest do
  use AdminAPI.ConnCase, async: true

  describe "/auth_token.switch_account" do
    test "gets access_key:unauthorized back" do
      account = insert(:account)

      # User belongs to the master account and has access to the sub account
      # just created
      response =
        provider_request("/auth_token.switch_account", %{
          "account_id" => account.id
        })

      refute response["success"]
      assert response["data"]["code"] == "access_key:unauthorized"
    end
  end

  describe "/me.logout" do
    test "gets access_key:unauthorized back" do
      response = provider_request("/me.logout")
      refute response["success"]
      assert response["data"]["code"] == "access_key:unauthorized"
    end
  end
end
