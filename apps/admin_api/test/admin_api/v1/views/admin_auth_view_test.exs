defmodule AdminAPI.V1.AdminAuthViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.{AdminAuthView, AuthTokenSerializer}

  describe "AdminAPI.V1.AuthView.render/2" do
    # Potential candidate to be moved to a shared library

    test "renders auth_token.json with correct structure" do
      auth_token = insert(:auth_token)

      expected = %{
        version: @expected_version,
        success: true,
        data: AuthTokenSerializer.serialize(auth_token)
      }

      attrs = %{auth_token: auth_token}
      assert AdminAuthView.render("auth_token.json", attrs) == expected
    end

    test "renders empty_response.json with correct structure" do
      expected = %{
        version: @expected_version,
        success: true,
        data: %{}
      }

      assert AdminAuthView.render("empty_response.json") == expected
    end
  end
end
