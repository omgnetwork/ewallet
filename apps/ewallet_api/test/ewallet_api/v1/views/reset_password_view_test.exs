defmodule EWalletAPI.V1.ResetPasswordViewTest do
  use EWalletAPI.ViewCase, :v1
  alias EWalletAPI.V1.ResetPasswordView

  describe "render/2" do
    test "renders empty.json correctly" do
      assert ResetPasswordView.render("empty.json", %{success: true}) ==
               %{
                 version: @expected_version,
                 success: true,
                 data: %{}
               }
    end
  end
end
