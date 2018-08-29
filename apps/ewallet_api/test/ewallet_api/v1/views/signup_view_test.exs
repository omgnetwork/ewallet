defmodule EWalletAPI.V1.SignupViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWallet.Web.V1.UserSerializer
  alias EWalletAPI.V1.SignupView

  describe "render/2" do
    test "renders empty.json correctly" do
      assert SignupView.render("empty.json", %{success: true}) ==
               %{
                 version: @expected_version,
                 success: true,
                 data: %{}
               }
    end

    test "renders user.json with the correct structure" do
      user = insert(:user)

      expected = %{
        version: @expected_version,
        success: true,
        data: UserSerializer.serialize(user)
      }

      assert SignupView.render("user.json", %{user: user}) == expected
    end
  end
end
