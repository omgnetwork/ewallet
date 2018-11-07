defmodule AdminAPI.V1.ProviderAuth.UpdateEmailControllerTest do
  use AdminAPI.ConnCase, async: true

  @redirect_url "http://localhost:4000/update_email?email={email}&token={token}"

  describe "/me.update_email" do
    test "gets access_key:unauthorized back" do
      response =
        provider_request("/me.update_email", %{
          "email" => "test_email_update@example.com",
          "redirect_url" => @redirect_url
        })

      refute response["success"]
      assert response["data"]["code"] == "access_key:unauthorized"
    end
  end
end
