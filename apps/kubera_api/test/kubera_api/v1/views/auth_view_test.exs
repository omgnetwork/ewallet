defmodule KuberaAPI.V1.AuthViewTest do
  use KuberaAPI.ViewCase, :v1
  alias KuberaAPI.V1.AuthView

  describe "KuberaAPI.V1.AuthView.render/2" do
    test "renders auth_token.json with correct structure" do
      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "authentication_token",
          authentication_token: "the_auth_token"
        }
      }

      attrs = %{auth_token: "the_auth_token"}
      assert AuthView.render("auth_token.json", attrs) == expected
    end

    test "renders empty_response.json with correct structure" do
      expected = %{
        version: @expected_version,
        success: true,
        data: %{}
      }

      assert AuthView.render("empty_response.json") == expected
    end
  end
end
