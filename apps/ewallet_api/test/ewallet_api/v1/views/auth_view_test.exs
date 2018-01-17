defmodule EWalletAPI.V1.AuthViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWalletAPI.V1.AuthView

  describe "EWalletAPI.V1.AuthView.render/2" do
    # Potential candidate to be moved to a shared library
    # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
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
